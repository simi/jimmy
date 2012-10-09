# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Josef Šimánek"]
  gem.email         = ["retro@ballgag.cz"]
  gem.description   = %q{Jimmy deploy system}
  gem.summary       = %q{Simple experiment for heroku like Rack deployment system}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'jimmy'
  gem.executables   = 'jimmy'
  gem.require_paths = ["lib"]
  gem.version       = "0.0.1"

  gem.add_dependency  'thor'
end
