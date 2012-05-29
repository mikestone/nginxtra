require "spec_helper"

describe Nginxtra::Actions::Start do
  let(:thor_mock) { Object.new }
  let(:config_mock) { Object.new }
  let(:compile_mock) { Object.new }
  let(:base_dir) { File.absolute_path File.expand_path("../..", __FILE__) }
  let(:nginx_conf_dir) { File.join(base_dir, "conf") }
  let(:executable) { File.join(base_dir, "build/nginx/sbin/nginx") }
  let(:pidfile) { File.join(base_dir, ".nginx_pid") }

  it "compiles then starts nginx" do
    Nginxtra::Actions::Compile.should_receive(:new).with(thor_mock, config_mock).and_return(compile_mock)
    compile_mock.should_receive(:compile)
    config_mock.should_receive(:files).and_return(["nginx.conf", "mime_types.conf"])
    config_mock.should_receive(:file_contents).with("nginx.conf").and_return("The nginx contents")
    config_mock.should_receive(:file_contents).with("mime_types.conf").and_return("The mime_types contents")
    thor_mock.stub(:inside).with(nginx_conf_dir).and_yield
    thor_mock.should_receive(:remove_file).with("nginx.conf")
    thor_mock.should_receive(:remove_file).with("mime_types.conf")
    thor_mock.should_receive(:create_file).with("nginx.conf", "The nginx contents")
    thor_mock.should_receive(:create_file).with("mime_types.conf", "The mime_types contents")
    thor_mock.should_receive(:run).with("start-stop-daemon --start --quiet --pidfile #{pidfile} --exec #{executable}")
    Time.stub(:now).and_return(:fake_time)
    Nginxtra::Status.should_receive(:[]=).with(:last_start_time, :fake_time)
    Nginxtra::Actions::Start.new(thor_mock, config_mock).start
  end

  it "throws an exception if nginx.conf is not specified" do
    Nginxtra::Actions::Compile.should_receive(:new).with(thor_mock, config_mock).and_return(compile_mock)
    compile_mock.should_receive(:compile)
    config_mock.should_receive(:files).and_return(["mime_types.conf"])
    lambda { Nginxtra::Actions::Start.new(thor_mock, config_mock).start }.should raise_error(Nginxtra::Error::InvalidConfig)
  end
end
