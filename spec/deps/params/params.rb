dep 'top-level dep with params', :param do
  requires 'a dep without params'
  requires 'another dep with params'.with(param)
end

dep 'a dep without params' do
end

dep 'another dep with params', :param do
end
