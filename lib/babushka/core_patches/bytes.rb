# Lifted from activesupport-3.0.5/lib/active_support/core_ext/numeric/bytes.rb
class Numeric
  KILOBYTE = 1024
  MEGABYTE = KILOBYTE * 1024
  GIGABYTE = MEGABYTE * 1024
  TERABYTE = GIGABYTE * 1024
  PETABYTE = TERABYTE * 1024
  EXABYTE  = PETABYTE * 1024

  # Enables the use of byte calculations and declarations, like 45.bytes + 2.6.megabytes
  def bytes
    self
  end
  alias :byte :bytes

  def kilobytes
    Babushka::LogHelpers.deprecated! '2017-09-01'
    self * KILOBYTE
  end
  alias :kilobyte :kilobytes

  def megabytes
    Babushka::LogHelpers.deprecated! '2017-09-01'
    self * MEGABYTE
  end
  alias :megabyte :megabytes

  def gigabytes
    Babushka::LogHelpers.deprecated! '2017-09-01'
    self * GIGABYTE
  end
  alias :gigabyte :gigabytes

  def terabytes
    Babushka::LogHelpers.deprecated! '2017-09-01'
    self * TERABYTE
  end
  alias :terabyte :terabytes

  def petabytes
    Babushka::LogHelpers.deprecated! '2017-09-01'
    self * PETABYTE
  end
  alias :petabyte :petabytes

  def exabytes
    Babushka::LogHelpers.deprecated! '2017-09-01'
    self * EXABYTE
  end
  alias :exabyte :exabytes

  alias :kb :kilobytes
  alias :mb :megabytes
  alias :gb :gigabytes
  alias :tb :terabytes
  alias :pb :petabytes
  alias :eb :exabytes
end
