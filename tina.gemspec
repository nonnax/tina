
Gem::Specification.new do |s|
  s.name = 'tina'
  s.version = '0.0.1'
  s.date = '2022-04-15'
  s.summary = "mini router"
  s.authors = ["xxanon"]
  s.email = "ironald@gmail.com"
  s.files = `git ls-files`.split("\n") - %w[bin misc]
  s.executables += `git ls-files bin`.split("\n").map{|e| File.basename(e)}
  s.homepage = "https://github.com/nonnax/tina.git"
  s.license = "GPL-3.0"
end

