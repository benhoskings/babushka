class Object
  def in? list
    list.include? self
  end
end

class String
  # Returns true iff +str+ appears exactly at the start of +self+.
  def starts_with? str
    self[0, str.length] == str
  end

  # Returns true iff +str+ appears exactly at the end of +self+.
  def ends_with? str
    self[-str.length, str.length] == str
  end

  # Return a duplicate of +self+, with +str+ prepended to it if it doesn't already start with +str+.
  def start_with str
    starts_with?(str) ? self : str + self
  end

  # Return a duplicate of +self+, with +str+ appended to it if it doesn't already end with +str+.
  def end_with str
    ends_with?(str) ? self : self + str
  end

  def val_for key
    split("\n").grep(key).first.sub(/^#{key}\:?/).strip
  end
  def / other
    File.join self, other
  end

  def colorize description = '', start_at = nil
    if start_at.nil? || (cut_point = index(start_at)).nil?
      Colorizer.colorize self, description
    else
      self[0...cut_point] + Colorizer.colorize(self[cut_point..-1], description)
    end
  end

  def colorize! description = '', start_at = nil
    replace colorize(description, start_at) unless description.blank?
  end

  private

  class Colorizer
    HomeOffset = 29
    LightOffset = 60
    BGOffset = 10
    LightRegex = /^light_/
    ColorRegex = /^(light_)?none|gr[ae]y|red|green|yellow|blue|pink|cyan|white$/
    CtrlRegex = /^bold|underlined?|blink(ing)?|reversed?$/
    ColorOffsets = {
      'none' => 0,
      'gray' => 61, 'grey' => 61,
      'red' => 2,
      'green' => 3,
      'yellow' => 4,
      'blue' => 5,
      'pink' => 6,
      'cyan' => 7,
      'white' => 8
    }
    CtrlOffsets = {
      'bold' => 1,
      'underline' => 4, 'underlined' => 4,
      'blink' => 5, 'blinking' => 5,
      'reverse' => 7, 'reversed' => 7
    }
    class << self
      def colorize text, description
        terms = " #{description} ".gsub(' light ', ' light_').gsub(' on ', ' on_').strip.split(/\s+/)
        bg = terms.detect {|i| /on_#{ColorRegex}/ =~ i }
        fg = terms.detect {|i| ColorRegex =~ i }
        ctrl = terms.detect {|i| CtrlRegex =~ i }

        "\e[#{"0;#{fg_for(fg)};#{bg_for(bg) || ctrl_for(ctrl)}"}m#{text}\e[0m"
      end

      def fg_for name
        light = name.gsub!(LightRegex, '') unless name.nil?
        (ColorOffsets[name] || 0) + HomeOffset + (light ? LightOffset : 0)
      end

      def bg_for name
        # There's a hole in the table on bg=none, so we use BGOffset to the left
        offset = fg_for((name || '').sub(/^on_/, ''))
        offset + BGOffset unless offset == HomeOffset
      end

      def ctrl_for name
        CtrlOffsets[name] || HomeOffset
      end
    end
  end
end
