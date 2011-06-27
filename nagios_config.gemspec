Gem::Specification.new do |s|
  s.name = "nagios_config"
  s.version = "0.0.3"
  s.summary = "Nagios config parser and friends"
  s.description = "Read and write Nagios config files from Ruby"
  s.files = %W{lib}.map {|dir| Dir["#{dir}/**/*.rb"]}.flatten << "README.rdoc"
  s.require_path = "lib"
  s.rdoc_options << "--main" << "README.rdoc" << "--charset" << "utf-8"
  s.extra_rdoc_files = ["README.rdoc"]
  s.author = "Matthew Sadler"
  s.email = "mat@sourcetagsandcodes.com"
  s.homepage = "http://github.com/matsadler/nagios_config"
  s.add_dependency("events", "~> 0.9.2")
end