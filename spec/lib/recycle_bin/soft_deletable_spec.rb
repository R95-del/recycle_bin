# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecycleBin::SoftDeletable do
  it 'is a module' do
    expect(RecycleBin::SoftDeletable).to be_a(Module)
  end

  it 'can be included in a class' do
    test_class = Class.new do
      include RecycleBin::SoftDeletable

      attr_accessor :deleted_at, :id, :title

      def initialize
        @id = 1
        @title = 'Test Item'
        @deleted_at = nil
      end
    end

    expect(test_class.ancestors).to include(RecycleBin::SoftDeletable)

    # Test instance methods
    instance = test_class.new
    expect(instance).to respond_to(:deleted?)
    expect(instance).to respond_to(:soft_delete)
    expect(instance).to respond_to(:restore)
    expect(instance).to respond_to(:recyclable_title)
  end

  it 'provides recyclable_title method' do
    test_class = Class.new do
      include RecycleBin::SoftDeletable

      attr_accessor :title, :id

      def initialize
        @id = 1
        @title = 'Test Title'
      end
    end

    instance = test_class.new
    expect(instance.recyclable_title).to eq('Test Title')
  end
end
