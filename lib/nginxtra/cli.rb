require "thor"

module Nginxtra
  class CLI < Thor
    include Thor::Actions

    class_option "force", :type => :boolean, :banner => "Force a task to happen, regardless of what nginxtra thinks", :aliases => "-f"
    class_option "non-interactive", :type => :boolean, :banner => "If nginxtra would ask a question, it instead proceeds as if 'no' were the answer", :aliases => "-I"
    class_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    class_option "basedir", :type => :string, :banner => "Specify the directory to store nginx files", :aliases => "-b"

    desc "compile", "Compiles nginx based on nginxtra.conf.rb"
    long_desc "
      Compile nginx with the compilation options specified in nginxtra.conf.rb.  If it
      has already been compiled with those options, compilation will be skipped.  Note
      that start will already run compilation, so compilation is not really needed to
      be executed directly.  However, you can force recompilation by running this task
      with the --force option."
    def compile
      Nginxtra::Actions::Compile.new(self, prepare_config!).compile
    end

    desc "install", "Installs nginxtra"
    long_desc "
      Install nginxtra so nginx will start at system startup time, and stop when the
      system is shut down.  Before installing, it will be checked if it had been
      already installed with this version of nginxtra.  If it was already installed,
      installation will be skipped unless the --force option is given."
    def install
      Nginxtra::Actions::Install.new(self, prepare_config!).install
    end

    desc "start", "Start nginx with configuration defined in nginxtra.conf.rb"
    long_desc "
      Start nginx based on nginxtra.conf.rb.  If nginx has not yet been compiled for
      the given compilation options or the current nginx version, it will be compiled.
      If nginxtra has not been installed for the current version, the user will be
      asked if it is ok to install. The configuration for nginx will automatically be
      handled by nginxtra so it matches what is defined in nginxtra.conf.rb.  If it is
      already running, this will do nothing, unless --force is passed.  Note that
      compilation and installation will NOT be forced with --force option.  The
      compile or install task should be invoked if those need to be forced."
    def start
      Nginxtra::Actions::Start.new(self, prepare_config!).start
    end

    desc "stop", "Stop nginx"
    long_desc "
      Stop nginx, unless it is already running based on the pidfile.  If it is
      determined to be running, this command will do nothing, unless --force is passed
      (which will cause it to run the stop command regardless of the pidfile)."
    def stop
      Nginxtra::Actions::Stop.new(self, prepare_config!).stop
    end

    desc "restart", "Restart nginx"
    def restart
      Nginxtra::Actions::Restart.new(self, prepare_config!).restart
    end
    map "force-reload" => "restart"

    desc "reload", "Reload nginx"
    def reload
      Nginxtra::Actions::Reload.new(self, prepare_config!).reload
    end

    desc "status", "Check if nginx is running"
    def status
      Nginxtra::Actions::Status.new(self, prepare_config!).status
    end

    private
    def prepare_config!
      Nginxtra::Config.base_dir = options["basedir"]
      result = Nginxtra::Config.require! options["config"]
      say "Using config #{Nginxtra::Config.loaded_config_path}"
      result
    end

    class << self
      def source_root
        File.absolute_path File.expand_path("../../..", __FILE__)
      end
    end
  end
end
