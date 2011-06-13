# #blank? means (nil? or empty?). Instead of defining it on all objects and
# checking if they respond to the #empty? method when #blank? is called, we
# define it only on the classes where it has meaning. That means we also
# have to define it on nil, since it is also considered 'blank'.

module Enumerable
  def blank?
    empty?
  end
end

class String
  def blank?
    empty?
  end
end

class NilClass
  def blank?
    true
  end
end
