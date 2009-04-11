class GemDepDefiner < DepDefiner

  attr_setter :pkg

  def payload
    super.merge({
      :met? => lambda {
        @pkg.all? {|pkg_name| GemHelper.has?(pkg_name) }
      },
      :meet => lambda {
        'lol'
      }
    })
  end

end
