class DiptablesCookbook
  class Exception < RuntimeError
    class << self
      attr_accessor :default_message
    end
    def initialize msg = nil
      super msg || self.class.default_message
    end

    class SearchNotSupported < Exception
      @default_message = 'This recipe uses search. Chef Solo does not support search unless you install the chef-solo-search cookbook.'
    end

    class InvalidResourceAttrs < Exception
    end

    class IptablesNotFound < Exception
      @default_message = 'The iptables executable could not be find in your PATH?'
    end

    class TcpdumpNotFound < Exception
      @default_message = 'The tcpdump executable could not be find in your PATH?'
    end

    class InvalidRule < Exception
    end

    class InexistingTable < Exception
    end
  end
end
