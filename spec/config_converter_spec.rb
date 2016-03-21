require "spec_helper"
require "stringio"

describe Nginxtra::ConfigConverter do
  let(:output) { StringIO.new }
  let(:converter) { Nginxtra::ConfigConverter.new output }

  it "raises an error if parsing happens twice" do
    converter.convert config: StringIO.new("")
    expect { converter.convert config: StringIO.new("") }.to raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "converts empty config to a simple config file" do
    converter.convert config: StringIO.new("")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
  end
end
)
  end

  it "converts simple config lines to config file" do
    converter.convert config: StringIO.new("user    my_user;
")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    user "my_user"
  end
end
)
  end

  it "uses commas when there are more than 1 argument" do
    converter.convert config: StringIO.new("this is an example;
")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    this "is", "an", "example"
  end
end
)
  end

  it "handles return, if and break keywords" do
    converter.convert config: StringIO.new("if (some ~ condition) {
  return something;
}

if (condition) {
  break another;
}
")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    _if "some", "~", "condition" do
      _return "something"
    end
    _if "condition" do
      _break "another"
    end
  end
end
)
  end

  it "deals with backslash property" do
    converter.convert config: StringIO.new("events \\.testing {
  worker_connections 10;
}")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    events "\\\\.testing" do
      worker_connections 10
    end
  end
end
)
  end

  it "ignores comments in a line" do
    converter.convert config: StringIO.new("# A header comment
user    my_user; # A line comment
")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    user "my_user"
  end
end
)
  end

  it "handles comments on the last line" do
    converter.convert config: StringIO.new("user    my_user;
# A line comment")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    user "my_user"
  end
end
)
  end

  it "converts multiple simple lines" do
    converter.convert config: StringIO.new("  user    my_user;

worker_processes     1;

")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    user "my_user"
    worker_processes 1
  end
end
)
  end

  it "handles multiple lines smooshed together" do
    converter.convert config: StringIO.new("user my_user;worker_processes 1;worker_processes 2;")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    user "my_user"
    worker_processes 1
    worker_processes 2
  end
end
)
  end

  it "handles simple blocks" do
    converter.convert config: StringIO.new("events {
}")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    events do
    end
  end
end
)
  end

  it "handles simple blocks with args" do
    converter.convert config: StringIO.new("events args {
}")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    events "args" do
    end
  end
end
)
  end

  it "handles simple blocks with several args" do
    converter.convert config: StringIO.new("events with multiple args {
}")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    events "with", "multiple", "args" do
    end
  end
end
)
  end

  it "handles simple blocks with content" do
    converter.convert config: StringIO.new("events {
  worker_connections 10;
}")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    events do
      worker_connections 10
    end
  end
end
)
  end

  it "can manage nested blocks with content" do
    converter.convert config: StringIO.new("events {
  nested_events {
    deeper_nested_events {
      worker_connections 10;
    }
  }
}")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    events do
      nested_events do
        deeper_nested_events do
          worker_connections 10
        end
      end
    end
  end
end
)
  end

  it "will deal with single line of nested blocks and values" do
    converter.convert config: StringIO.new("events{value 1;nested_events{deeper_nested_events{worker_connections 10;inner_value 2;}}}")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    events do
      value 1
      nested_events do
        deeper_nested_events do
          worker_connections 10
          inner_value 2
        end
      end
    end
  end
end
)
  end

  it "parses passenger lines" do
    converter.convert config: StringIO.new("http {
  passenger_root /path/to/passenger-1.2.3;
  passenger_ruby /the/path/to/ruby;
  passenger_enabled on;
}")
    expect(output.string).to eq %(nginxtra.config do
  file "nginx.conf" do
    http do
      passenger_root!
      passenger_ruby!
      passenger_on!
    end
  end
end
)
  end

  it "detects invalidly nested blocks" do
    expect do
      converter.convert config: StringIO.new("events {
  worker_connections 10;")
    end.to raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "detects bad line endings" do
    expect { converter.convert config: StringIO.new("worker_connections 10") }.to raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "detects bad line endings within block" do
    expect { converter.convert config: StringIO.new("event { worker_connections 10 }") }.to raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "detects bad line endings with 1 label within block" do
    expect { converter.convert config: StringIO.new("event { worker_connections }") }.to raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "fails with blocks with no label" do
    expect { converter.convert config: StringIO.new("{ worker_connections 10; }") }.to raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "fails with empty lines" do
    expect { converter.convert config: StringIO.new(";") }.to raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "will deal with no compile arguments" do
    converter.convert binary_status: "nginx version: nginx/1.2.3
built by gcc 1.2.3
configure arguments:
"
    expect(output.string).to eq %(nginxtra.config do
end
)
  end

  it "will deal with one argument" do
    converter.convert binary_status: "nginx version: nginx/1.2.3
built by gcc 1.2.3
configure arguments: --test
"
    expect(output.string).to eq %(nginxtra.config do
  compile_option "--test"
end
)
  end

  it "will deal with several arguments" do
    converter.convert binary_status: "nginx version: nginx/1.2.3
built by gcc 1.2.3
configure arguments: --test --other --another-arg
"
    expect(output.string).to eq %(nginxtra.config do
  compile_option "--test"
  compile_option "--other"
  compile_option "--another-arg"
end
)
  end

  it "ignores the invalid options" do
    converter.convert binary_status: "nginx version: nginx/1.2.3
built by gcc 1.2.3
configure arguments: --prefix=./whatever --sbin-path=./sbin/value --conf-path=my/conf/path --pid-path=my/pid/path --test
"
    expect(output.string).to eq %(nginxtra.config do
  compile_option "--test"
end
)
  end

  it "detects passenger options" do
    converter.convert binary_status: "nginx version: nginx/1.2.3
built by gcc 1.2.3
configure arguments: --with-http_ssl_module --testing --with-http_gzip_static_module --another-test --add-module=/my/path/to/passenger-1.2.3/ext/nginx --with-cc-opt=-Wno-error
"
    expect(output.string).to eq %(nginxtra.config do
  require_passenger!
  compile_option "--testing"
  compile_option "--another-test"
end
)
  end
end
