class String

  private

  class Colorizer

    HOME_OFFSET = 29
    LIGHT_OFFSET = 60
    BG_OFFSET = 10
    LIGHT_REGEX = /^light_/
    COLOR_REGEX = /^(light_)?none|gr[ae]y|red|green|yellow|blue|pink|cyan|white$/
    CTRL_REGEX = /^bold|underlined?|blink(ing)?|reversed?$/
    COLOR_OFFSETS = {
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
    CTRL_OFFSETS = {
      'bold' => 1,
      'underline' => 4, 'underlined' => 4,
      'blink' => 5, 'blinking' => 5,
      'reverse' => 7, 'reversed' => 7
    }

    def self.colorize text, description
      return text if Babushka::Base.cmdline.opts[:"[no_]color"] == false

      terms = " #{description} ".gsub(' light ', ' light_').gsub(' on ', ' on_').strip.split(/\s+/)
      bg = terms.detect {|i| /on_#{COLOR_REGEX}/ =~ i }
      fg = terms.detect {|i| COLOR_REGEX =~ i }
      ctrl = terms.detect {|i| CTRL_REGEX =~ i }

      "\e[#{"0;#{fg_for(fg)};#{bg_for(bg) || ctrl_for(ctrl)}"}m#{text}\e[0m"
    end

    def self.fg_for name
      light = name.gsub!(LIGHT_REGEX, '') unless name.nil?
      (COLOR_OFFSETS[name] || 0) + HOME_OFFSET + (light ? LIGHT_OFFSET : 0)
    end

    def self.bg_for name
      # There's a hole in the table on bg=none, so we use BG_OFFSET to the left
      offset = fg_for((name || '').sub(/^on_/, ''))
      offset + BG_OFFSET unless offset == HOME_OFFSET
    end

    def self.ctrl_for name
      CTRL_OFFSETS[name] || HOME_OFFSET
    end
  end

end
