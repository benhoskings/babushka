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

    case value
    when 0; return 'now'
    when 1...60; return "less than a minute#{' ago' if past}"
    when 61...3600;        value /= 60;        unit = 'minute'
    when 3600...(3600*24); value /= 3600;      unit = 'hour'
    else                   value /= (3600*24); unit = 'day'
    end

    value = 1 if value == 0
    "#{value.commas} #{unit}#{'s' unless value == 1}#{' ago' if past}"
  end
end
