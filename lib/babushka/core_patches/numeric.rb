class Numeric
  # Return a string representation of this value with commas between the
  # thousands groupings.
  # Some examples:
  # 3.commas     #=> "3"
  # 314.commas   #=> "314"
  # 31459.commas #=> "31,459"
  def commas
    if self < 1000
      to_s
    else
      whole, fract = self.to_s.split('.')
      [ whole.reverse.scan(/\d{1,3}/).join(',').reverse, fract ].squash.join('.')
    end
  end
end
