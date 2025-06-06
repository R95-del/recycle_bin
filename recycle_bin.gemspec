# frozen_string_literal: true

require_relative 'lib/recycle_bin/version'

Gem::Specification.new do |spec|
  spec.name = 'recycle_bin'
  spec.version = RecycleBin::VERSION
  spec.authors = ['Rishi Somani', 'Shobhit Jain', 'Raghav Agrawal']
  spec.email = ['somani.rishi81@gmail.com', 'shobhjain09@gmail.com', 'raghavagrawal019@gmail.com']

  spec.summary = 'Soft delete and trash management for Ruby on Rails applications'
  spec.description = 'RecycleBin provides soft delete functionality with a user-friendly trash/recycle bin interface for any Rails application. Easily restore deleted records with a simple web interface.'
  spec.homepage = 'https://github.com/R95-del/recycle_bin'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      # Exclude the gemspec file itself and development files
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github]) ||
        f.match?(/\A\./) ||          # Exclude dotfiles
        f.end_with?('.gem') ||       # Exclude any .gem files
        f.include?('Gemfile.lock')   # Exclude Gemfile.lock
    end
  end

  spec.require_paths = ['lib']

  # Runtime dependencies - Use pessimistic version constraints
  spec.add_dependency 'rails', '>= 6.0', '< 9.0'

  # Development dependencies - FIXED to match Gemfile
  spec.add_development_dependency 'factory_bot_rails', '~> 6.2'
  spec.add_development_dependency 'rspec-rails', '>= 6.0'  # Changed from '~> 6.0'
  spec.add_development_dependency 'sqlite3', '~> 2.0'      # Changed from '~> 2.1'

  # Gem metadata with distinct URIs
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/R95-del/recycle_bin'
  spec.metadata['changelog_uri'] = 'https://github.com/R95-del/recycle_bin/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/R95-del/recycle_bin/issues'
  spec.metadata['documentation_uri'] = 'https://github.com/R95-del/recycle_bin/blob/main/README.md'
  spec.metadata['wiki_uri'] = 'https://github.com/R95-del/recycle_bin/wiki'
end
