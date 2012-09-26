require File.expand_path("../lib/nginxtra/version.rb", __FILE__)

def system_exec(cmd)
  puts "Executing: #{cmd}"
  results = %x[#{cmd}]
  puts results unless results.strip.empty?
end

module Nginxtra
  class Gem
    class << self
      def dependencies
        { :thor => "~> 0.16.0" }
      end

      def to_s
        "nginxtra-#{Nginxtra::Version}.gem"
      end
    end
  end
end

def update_version(next_version)
  puts "Generating version.rb"
  File.write File.expand_path("../lib/nginxtra/version.rb", __FILE__), %{module Nginxtra
  class Version
    class << self
      def to_a
        to_s.split(".").map &:to_i
      end

      def to_s
        "#{next_version}"
      end
    end
  end
end
}
  load File.expand_path("../lib/nginxtra/version.rb", __FILE__)
  Rake::Task[:generate].execute
end

def update_nginx
  doc = Nokogiri::HTML(open("http://nginx.org/en/download.html"))
  stable_node = doc.search "[text()*='Stable version']"

  if stable_node.size != 1
    puts "Could not find just 1 'Stable version' node, found #{stable_node.size}"
    return
  end

  results = doc.search("[text()*='Stable version']").first.parent.next.search("a").select { |x| x.attr("href") =~ /\/nginx-\d+\.\d+\.\d+\.tar\.gz$/ }

  if results.size != 1
    puts "Could not find just 1 link for the nginx-VERSION.tar.gz download, found #{results.size}"
    return
  end

  path = results.first.attr "href"

  unless path =~ /^\/(?:.*\/)?nginx-(\d+\.\d+\.\d+)\.tar\.gz$/
    puts "Unexpected path style, expected /something, got: '#{path}'"
    return
  end

  next_version = Regexp.last_match[1]
  filename = "nginx-#{next_version}.tar.gz"
  full_output_path = File.expand_path "../#{filename}", __FILE__

  if File.exists? full_output_path
    puts "Skipping already downloaded file"
  else
    url = "http://nginx.org#{path}"
    puts "Downloading from #{url}"

    open url do |download|
      File.open full_output_path, "w" do |out|
        out.write download.read
      end
    end
  end

  vendor_path = File.expand_path "../vendor", __FILE__
  nginx_path = File.join vendor_path, "nginx"
  extracted_dir = File.expand_path "../vendor/nginx-#{next_version}", __FILE__
  system_exec "git rm -r #{nginx_path}"
  system_exec "mkdir #{vendor_path}"
  system_exec "tar -C #{vendor_path} -xz -f #{full_output_path}"
  system_exec "mv #{extracted_dir} #{nginx_path}"
  system_exec "git add #{nginx_path}"
  update_version "#{next_version}.#{Nginxtra::Version.to_a[-1]}"
end

task :default => :install

task :update_nginx do
  gem "nokogiri"
  require "nokogiri"
  require "open-uri"
  update_nginx
end

task :increment_version do
  parts = Nginxtra::Version.to_a
  parts[-1] += 1
  next_version = parts.join "."
  update_version next_version
end

task :decrement_version do
  parts = Nginxtra::Version.to_a
  parts[-1] -= 1
  next_version = parts.join "."
  update_version next_version
end

task :generate do
  puts "Generating nginxtra.gemspec"
  File.write File.expand_path("../nginxtra.gemspec", __FILE__), %{# Note: This gemspec generated by the Rakefile
require "rubygems/package_task"

Gem::Specification.new do |s|
  s.name           = "nginxtra"
  s.version        = "#{Nginxtra::Version}"
  s.summary        = "Wrapper of nginx for easy install and use."
  s.description    = "This gem is intended to provide an easy to use configuration file that will automatically be used to compile nginx and configure the configuration."
  s.author         = "Mike Virata-Stone"
  s.email          = "reasonnumber@gmail.com"
  s.files          = FileList["bin/**/*", "lib/**/*", "templates/**/*", "vendor/**/*"]
  s.require_path   = "lib"
  s.bindir         = "bin"
  s.executables    = ["nginxtra", "nginxtra_rails"]
  s.homepage       = "http://reasonnumber.com/nginxtra"
  s.add_dependency "thor", "#{Nginxtra::Gem.dependencies[:thor]}"
end
}

  puts "Generating bin/nginxtra"
  File.write File.expand_path("../bin/nginxtra", __FILE__), %{#!/usr/bin/env ruby
require "rubygems"
gem "nginxtra", "= #{Nginxtra::Version}"
gem "thor", "#{Nginxtra::Gem.dependencies[:thor]}"
require "nginxtra"
Nginxtra::CLI.start
}

  puts "Generating bin/nginxtra_rails"
  File.write File.expand_path("../bin/nginxtra_rails", __FILE__), %{#!/usr/bin/env ruby
require "rubygems"
gem "nginxtra", "= #{Nginxtra::Version}"
gem "thor", "#{Nginxtra::Gem.dependencies[:thor]}"
require "nginxtra"
Nginxtra::Rails::CLI.start
}
end

task :build => :generate do
  puts "Building nginxtra"
  system_exec "gem build nginxtra.gemspec"
end

task :install => :build do
  puts "Installing nginxtra"
  system_exec "gem install --no-ri --no-rdoc #{Nginxtra::Gem}"
end

task :tag do
  puts "Tagging nginxtra"
  system_exec "git tag -a #{Nginxtra::Version} -m 'Version #{Nginxtra::Version}' && git push --tags"
end

task :push => :build do
  puts "Pushing nginxtra"
  system_exec "gem push #{Nginxtra::Gem}"
end
