class Module
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
