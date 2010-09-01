class Module
  # Provides a delegate class method to easily expose contained objects' methods
  # as your own. Pass one or more methods (specified as symbols or strings)
  # and the name of the target object via the <tt>:to</tt> option (also a symbol
  # or string). At least one method and the <tt>:to</tt> option are required.
  #
  # (Adapted from active_support/core_ext/module/delegation.rb#delegate)
  def delegate *args
    opts = args.last.is_a?(Hash) ? args.pop : {}
    raise ArgumentError, "You need to supply :to => target as the final argument." if opts[:to].nil?

    file, line = caller.first.split(':', 2)
    line = line.to_i

    args.each {|method_name|
      module_eval <<-EOS, file, line
        def #{method_name} *args, &block
          #{opts[:to]}.__send__ #{method_name.inspect}, *args, &block
        end
      EOS
    }
  end
end
