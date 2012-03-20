# -*- coding: utf-8 -*-

require 'rubygems'
require 'rake/testtask'
require 'rake/clean'
require 'rubygems/package_task'

task :default => [:test]


Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files =  Dir.glob("test/*_test.rb")
end

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "A CLI Flashcard."
  s.name = 'ankit'
  s.version = "0.0.5"
  s.require_path = 'lib'
  s.files       = FileList["{bin,docs,lib,test}/**/*"].exclude("rdoc").to_a
  s.executables << 'ankit'
  s.add_runtime_dependency "highline", [">= 1.6.11"]
  s.add_runtime_dependency "diff-lcs", [">= 1.1.3"]
  s.add_runtime_dependency "json", [">= 1.6.5"]
  s.add_development_dependency "mocha", [">= 0.10.4"]
  s.authors     = ["Hajime Morrita"]
  s.email       = 'omo@dodgson.org'
  s.homepage    = 'https://github.com/omo/ankit'
  s.description = <<EOF
Ankit is a CLI and terminal based flashcard program to learn your new language.
EOF
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

CLEAN.include("pkg")
	