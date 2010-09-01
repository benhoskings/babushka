class IO
  # Return true iff reading from this IO object would return data immediately,
  # and not block while waiting for data.
  def ready_for_read?
    result = IO.select([self], [], [], 0)
    result && (result.first.first == self)
  end
end
