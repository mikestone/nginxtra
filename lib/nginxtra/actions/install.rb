module Nginxtra
  module Actions
    # The Nginxtra::Actions::Install class encapsulates installing
    # nginxtra so that nginx can be started and stopped automatically
    # when the server is started or stopped.
    class Install
      include Nginxtra::Action

      # Run the installation of nginxtra.
      def install
        return up_to_date unless should_install?
        create_etc_script
        update_last_install
      end

      # Create a script in the base directory which be symlinked to
      # /etc/init.d/nginxtra and then used to start and stop nginxtra
      # via update-rc.d.
      def create_etc_script
        filename = "etc.init.d.nginxtra"

        @thor.inside Nginxtra::Config.base_dir do
          @thor.create_file filename, %{#!/bin/sh
export GEM_HOME="#{ENV["GEM_HOME"]}"
export GEM_PATH="#{ENV["GEM_PATH"]}"
#{`which ruby`.strip} "#{File.join Nginxtra::Config.gem_dir, "bin/nginxtra"}" "$1" --basedir="#{Nginxtra::Config.base_dir}" --config="#{Nginxtra::Config.loaded_config_path}"
}, :force => true
          @thor.chmod filename, 0755
        end

        @thor.run %{#{sudo true}rm /etc/init.d/nginxtra && #{sudo true}ln -s "#{File.join Nginxtra::Config.base_dir, filename}" /etc/init.d/nginxtra}
      end

      # Notify the user that installation should be up to date.
      def up_to_date
        @thor.say "nginx installation is up to date"
      end

      # Mark the last installed version and last installed time (the
      # former being used to determine if nginxtra has been installed
      # yet).
      def update_last_install
        Nginxtra::Status[:last_install_version] = Nginxtra::Config.version
        Nginxtra::Status[:last_install_time] = Time.now
      end

      # Determine if the install should proceed.  This will be true if
      # the force option was used, or if this version of nginxtra
      # differs from the last version installed.
      def should_install?
        return true if @options[:force]
        Nginxtra::Status[:last_install_version] != Nginxtra::Config.version
      end
    end
  end
end
