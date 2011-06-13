module Babushka
  class IP
    attr_reader :bytes

    def initialize input
      @bytes = sanitize input
    end

    def to_s
      bytes.join '.'
    end

    def == other
      bytes == other.bytes
    end

    # Returns whether this IP should be considered a valid one for a client to be using.
    def valid?
      [:public, :private, :loopback].include? describe
    end

    def next
      offset_by 1
    end

    def prev
      offset_by -1
    end

    private

    def sanitize input
      if input.is_a? IP
        input.bytes.dup
      elsif input.is_a? Array
        input.select {|i| (0..255).include? i }
      else
        parse_and_sanitize input do |str,val|
          val if ((1..255) === val) || (val == 0 && str == '0')
        end
      end
    end

    def parse_and_sanitize input, &block
      parts = input.strip.split('.')
      bytes = parts.zip(
        parts.map(&:to_i)
      ).map {|(str,val)|
        yield str, val
      }.compact
    end

    def offset_by offset
      IP.new bytes.reverse.inject([offset]) {|acc,byte|
        carry, next_byte = (byte + acc.pop).divmod(256)
        acc.push next_byte
        acc.push carry
      }[0...4].reverse.join('.')
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
        [0, 255].include?(bytes[2]) ? :reserved : :self_assigned
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

    def padded_bytes
      bytes.concat(['x'] * (4 - bytes.length))
    end

    def ip_for address_part
      IP.new padded_bytes.zip(
        IPTail.new(address_part).padded_bytes
      ).map {|(network, address)|
        [network, address, 0].detect {|i| i != 'x' }
      }
    end

    def first
      ip_for 'x.0.0.1'
    end

    def last
      ip_for 'x.255.255.255'
    end

    def subnet
      padded_bytes.map {|byte|
        byte == 'x' ? '0' : '255'
      }.join('.')
    end

    def broadcast
      padded_bytes.map {|byte|
        byte == 'x' ? '255' : byte
      }.join('.')
    end

    private
    def sanitize input
      if /^\d+(\.\d+)*(\.x)+$/ !~ input
        []
      else
        parse_and_sanitize input.gsub(/x(\.x)*$/, 'x') do |str,val|
          if ((1..255) === val) || (val == 0 && str == '0')
            val
          elsif str == 'x'
            str
          end
        end
      end
    end
  end

  class IPTail < IPRange
    def padded_bytes
      (['x'] * (4 - bytes.length)).concat bytes
    end
    private
    def sanitize input
      super(input.split('.').reverse.join('.')).reverse
    end
  end
end
