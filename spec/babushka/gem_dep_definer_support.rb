def make_test_gems
  gem 'single gem with version' do
    installs 'gem1' => '1.2.3'
  end
  gem 'multiple gems with version' do
    installs 'gem2' => '0.1.4', 'gem3' => '0.2.5.1'
  end
end
