# frozen_string_literal: true

require_relative "lib/activerecord_cached/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord_cached"
  spec.version = ActiveRecordCached::VERSION
  spec.authors = ["Janosch Müller"]
  spec.email = ["janosch84@gmail.com"]

  spec.summary = "Flexibly cache ActiveRecord queries across requests"
  spec.homepage = "https://github.com/jaynetics/activerecord_cached"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jaynetics/activerecord_cached"
  spec.metadata["changelog_uri"] = "https://github.com/jaynetics/activerecord_cached/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"
end
