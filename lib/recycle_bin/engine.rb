# frozen_string_literal: true

require 'rails/engine'

module RecycleBin
  # Rails Engine for RecycleBin functionality
  class Engine < ::Rails::Engine
    isolate_namespace RecycleBin

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
