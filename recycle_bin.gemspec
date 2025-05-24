# frozen_string_literal: true

require_relative "lib/recycle_bin/version"

Gem::Specification.new do |spec|
  spec.name = "recycle_bin"
  spec.version = RecycleBin::VERSION
  spec.authors = ["Rishi Somani", "Shobhit Jain", "Raghav Agrawal"]
  spec.email = ["somani.rishi81@gmail.com"]

  spec.summary = "Simple soft delete and trash management for Rails"
  spec.description = "Add a recycle bin to your Rails app. Soft delete records and restore them with a simple web interface."
  spec.homepage = "https://github.com/R95-del/recycle_bin"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git])
    end
  end

  spec.require_paths = ["lib"]

  # V1 MVP Dependencies - Keep it minimal
  spec.add_dependency "rails", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "factory_bot_rails"
end
