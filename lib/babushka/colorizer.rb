class String

  private

  class Colorizer

    HOME_OFFSET = 29
    BG_OFFSET = 10
    COLOR_REGEX = /none|gr[ae]y|red|green|yellow|blue|pink|cyan|white/
    FG_REGEX = /\b#{COLOR_REGEX}\b/
    BG_REGEX = /\bon_#{COLOR_REGEX}\b/
    CTRL_REGEX = /\bbold|underlined?|blink(ing)?|reversed?\b/
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

      "#{escape_for(description)}#{text}\e[0m"
    end

    def self.escape_for description
      desc = description.strip.gsub(/\bon /, 'on_')
      bg = desc[BG_REGEX]
      fg = desc[FG_REGEX]
      ctrl = desc[CTRL_REGEX]

      "\e[#{"0;#{fg_for(fg)};#{bg_for(bg) || ctrl_for(ctrl)}"}m"
    end

    def self.fg_for name
      (COLOR_OFFSETS[name] || 0) + HOME_OFFSET
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
