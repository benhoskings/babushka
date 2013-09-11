class String

  private

  class Colorizer

    BG_OFFSET = 10
    COLOR_REGEX = /gr[ae]y|red|green|yellow|blue|pink|cyan|white/
    FG_REGEX = /\b#{COLOR_REGEX}\b/
    BG_REGEX = /\bon_#{COLOR_REGEX}\b/
    CTRL_REGEX = /\bbold|underlined?|blink(ing)?|reversed?\b/
    COLOR_OFFSETS = {
      'gray' => 90, 'grey' => 90,
      'red' => 31,
      'green' => 32,
      'yellow' => 33,
      'blue' => 34,
      'pink' => 35,
      'cyan' => 36,
      'white' => 37
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
      bg = bg_for(desc)
      fg = fg_for(desc)
      ctrl = ctrl_for(desc)

      "\e[0;#{fg};#{bg || ctrl}m"
    end

    def self.fg_for desc
      COLOR_OFFSETS[desc[FG_REGEX]] || 0
    end

    def self.bg_for desc
      # There's a hole in the table on bg=none, so we use BG_OFFSET to the left
      offset = fg_for((desc[BG_REGEX] || '').sub(/^on_/, ''))
      offset + BG_OFFSET unless offset == 0
    end

    def self.ctrl_for desc
      CTRL_OFFSETS[desc[CTRL_REGEX]] || (1 if desc[FG_REGEX]) || 0
    end
  end

end
