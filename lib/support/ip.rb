module Babushka
  class IP
    attr_reader :bytes

    def initialize input
      @bytes = sanitize input
    end

    # Returns whether this IP should be considered a valid one for a client to be using.
    def valid?
      describe.in? :public, :private, :loopback
    end

    private

    def sanitize input
      parse_and_sanitize input do |str,val|
        val if ((1..255) === val) || (val == 0 && str == '0')
      end
    end

    def parse_and_sanitize input, &block
      parts = input.strip.split('.')
      bytes = parts.zip(
        parts.map(&:to_i)
      ).map {|(str,val)|
        yield str, val
      }.squash
    end

    # Returns a symbol describing the class of IP address +self+ represents, if any.
    #
    # Examples:
    #
    #     "Hello world!".valid_ip?   #=> false
    #     "192.168.".valid_ip?       #=> false
    #     "127.0.0.1".valid_ip?      #=> :loopback
    #     "172.24.137.6".valid_ip?   #=> :private
    #     "169.254.1.142".valid_ip?  #=> :self_assigned
    #     "72.9.108.122".valid_ip?   #=> :public
    def describe
      if bytes.length != 4
        false
      elsif bytes.starts_with? 0 # Source hosts on "this" network
        :reserved
      elsif bytes.starts_with? 127 # Loopback network; RFC1700
        :loopback
      elsif bytes.starts_with? 10 # Class-A private; RFC1918
        :private
      elsif bytes.starts_with?(172) && ((16..31) === bytes[1]) # Class-B private; RFC1918
        :private
      elsif bytes.starts_with? 169, 254 # Link-local range; RFC3330/3927
        bytes[2].in?(0, 255) ? :reserved : :self_assigned
      elsif bytes.starts_with? 192, 0, 2 # TEST-NET - used as example.com IP
        :reserved
      elsif bytes.starts_with? 192, 88, 99 # 6-to-4 relay anycast; RFC3068
        :reserved
      elsif bytes.starts_with? 192, 168 # Class-C private; RFC1918
        :private
      elsif bytes.starts_with? 198, 18 # Benchmarking; RFC2544
        :reserved
      else
        :public
      end
    end
  end

  class IPRange < IP
    def valid?
      !bytes.empty?
    end
    
    private
    def sanitize input
      if /^\d+(\.\d+)*(\.x)+$/ !~ input
        []
      else
        parse_and_sanitize input do |str,val|
          if ((1..255) === val) || (val == 0 && str == '0')
            val
          elsif str == 'x'
            str
          end
        end
      end
    end
  end
end
