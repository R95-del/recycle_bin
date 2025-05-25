# frozen_string_literal: true

require 'rails/engine'

module RecycleBin
  class Engine < ::Rails::Engine
    isolate_namespace RecycleBin

    config.generators do |g|
      g.test_framework :rspec
    end

    # This ensures generators are found
    config.app_generators do |g|
      g.rails = {
        assets: false,
        helper: false
      }
    end
  end
end
