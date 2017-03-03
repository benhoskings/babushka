meta 'test_meta_1' do
end

dep 'test dep 1' do
end

dep 'test dep 2' do
end

def top_level_method_from_the_dep
  # This method shouldn't pollute the global namespace on load, because we're
  # using load(..., true).
end
