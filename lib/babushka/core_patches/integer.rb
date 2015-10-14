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
      divisor, threshold, unit = [
        [1, 1, 'less than a minute'],
        [60, 50, 'minute'],
        [3600, 3600, 'hour'],
        [3600*24, 3600*24, 'day'],
        [3600*24*7, 3600*24*7, 'week'],
        [3600*24*30, 3600*24*28, 'month'], # 28: 4 weeks
        [3600*24*365, 3600*24*360, 'year'], # 360: 12 30-day months
        [1, :infinity, 'forever']
      ].each_cons(2).detect {|(this_threshold, next_threshold)|
        next_threshold[1] == :infinity || value < next_threshold[1]
      }.first

      value /= divisor
      value = 1 if value == 0
      "#{value.commas} #{unit}#{'s' unless value == 1}#{' ago' if past}"
    end

  end
end
