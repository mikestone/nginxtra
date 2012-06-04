module Nginxtra
  module Error
    # Raised when an invalid configuration is specified, such as the
    # --prefix compile option.
    class InvalidConfig < StandardError; end

    # Raised when the config file cannot be found.
    class MissingConfig < StandardError; end

    # Raised when a run command fails
    class RunFailed < StandardError; end
  end
end
