require_relative 'lib/ford_johnson/version'

Gem::Specification.new do |s|
  s.name = 'ford_johnson'
  s.summary = 'An implementation of the Ford-Johnson sorting algorithm, ' \
    'also known as "merge-insertion sort".'
  s.authors = ["Tom Dalling"]
  s.email = [["tom", "@", "tomdalling.com"].join]
  s.homepage = 'https://github.com/tomdalling/ford_johnson'
  s.license = 'MIT'
  s.version = FordJohnson::VERSION
  s.files = Dir["lib/**/*.rb"]

  s.add_development_dependency 'rspec', '~> 3.9'
  s.add_development_dependency 'byebug'
end
