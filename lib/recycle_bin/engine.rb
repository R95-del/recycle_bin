# frozen_string_literal: true

require 'rails/engine'

module RecycleBin
  class Engine < ::Rails::Engine
    isolate_namespace RecycleBin

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
