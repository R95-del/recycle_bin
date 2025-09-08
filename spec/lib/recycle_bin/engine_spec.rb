# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecycleBin::Engine do
  describe 'class definition' do
    it 'is defined' do
      expect(described_class).to be_a(Class)
    end

    it 'is in RecycleBin module' do
      expect(described_class.name).to eq('RecycleBin::Engine')
    end

    it 'can be accessed via module' do
      expect(RecycleBin::Engine).to eq(described_class)
    end
  end

  describe 'configuration' do
    it 'has config method' do
      expect(described_class).to respond_to(:config)
    end

    it 'can access config' do
      config = described_class.config
      expect(config).to be_present
    end
  end

  if defined?(Rails)
    describe 'Rails integration' do
      it 'inherits from Rails::Engine' do
        expect(described_class.ancestors).to include(Rails::Engine)
      end
    end
  else
    describe 'without Rails' do
      it 'still has basic functionality' do
        expect(described_class).to be_a(Class)
      end
    end
  end
end
