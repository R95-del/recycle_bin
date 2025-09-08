# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecycleBin::SoftDeletable do
  describe 'configuration' do
    it 'can be configured' do
      RecycleBin.configure do |config|
        config.enable_web_interface = false
        config.items_per_page = 50
      end

      expect(RecycleBin.config.enable_web_interface).to be false
      expect(RecycleBin.config.items_per_page).to eq(50)
    end

    it 'has default values' do
      config = RecycleBin::Configuration.new
      expect(config.enable_web_interface).to be true
      expect(config.items_per_page).to eq(25)
      expect(config.max_items_per_page).to eq(1000)
    end
  end

  describe 'validation' do
    it 'validates configuration correctly' do
      config = RecycleBin::Configuration.new
      expect(config.valid?).to be true

      # Test invalid configuration
      config.search_settings[:min_search_length] = 5
      config.search_settings[:max_search_length] = 3
      expect(config.valid?).to be false
      expect(config.errors).to include('min_search_length cannot be greater than max_search_length')
    end
  end

  describe 'stats' do
    it 'returns stats hash structure' do
      stats = RecycleBin.stats
      expect(stats).to be_a(Hash)
      expect(stats).to have_key(:deleted_items)
      expect(stats).to have_key(:models_with_soft_delete)
      expect(stats).to have_key(:deleted_today)
      expect(stats).to have_key(:deleted_this_week)
    end
  end

  describe 'deleted items collection' do
    it 'handles empty collection' do
      collection = RecycleBin::DeletedItemsCollection.new([])
      expect(collection.count).to eq(0)
      expect(collection.empty?).to be true
    end

    it 'handles items collection' do
      items = [1, 2, 3]
      collection = RecycleBin::DeletedItemsCollection.new(items)
      expect(collection.count).to eq(3)
      expect(collection.empty?).to be false
    end

    it 'supports offset and limit' do
      items = [1, 2, 3, 4, 5]
      collection = RecycleBin::DeletedItemsCollection.new(items)

      offset_collection = collection.offset(2)
      expect(offset_collection.to_a).to eq([3, 4, 5])

      limited_collection = collection.limit(3)
      expect(limited_collection.to_a).to eq([1, 2, 3])
    end
  end
end
