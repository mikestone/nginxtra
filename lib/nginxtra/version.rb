module Nginxtra
  class Version
    class << self
      def to_a
        to_s.split(".").map &:to_i
      end

      def to_s
        "1.6.0.9"
      end
    end
  end
end
