class Integer
  # Return a string describing this integer as a human-readable, approximated
  # duration, assuming it is a number of seconds. The description will be
  # either 'now', 'less than a minute', or a value in minutes, hours or days.
  # Some examples:
  #   12.xsecs      #=> "less than a minute"
  #   80.xsecs      #=> "1 minute"
  #   1337.xsecs    #=> "22 minutes"
  #   1234567.xsecs #=> "14 days"
  def xsecs
    value = self.abs
    past = (self < 0)

    if value == 0
      'now'
    elsif value < 60
      "less than a minute#{' ago' if past}"
    else
      divisor, unit = [
        [1, 'less than a minute'],
        [60, 'minute'],
        [3600, 'hour'],
        [3600*24, 'day'],
        [Float::INFINITY, 'lawl']
      ].each_cons(2).detect {|(this_threshold, next_threshold)|
        value < next_threshold.first
      }.first

      value /= divisor
      "#{value.commas} #{unit}#{'s' unless value == 1}#{' ago' if past}"
    end

  end
end
