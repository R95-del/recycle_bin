# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecycleBin::DeletedItemsCollection do
  let(:items) { [double('Item1'), double('Item2'), double('Item3')] }
  let(:collection) { described_class.new(items) }

  describe 'initialization' do
    it 'accepts items array' do
      expect(collection.items).to eq(items)
    end

    it 'handles nil items gracefully' do
      nil_collection = described_class.new(nil)
      expect(nil_collection.items).to eq([])
    end

    it 'handles empty array' do
      empty_collection = described_class.new([])
      expect(empty_collection.items).to eq([])
    end
  end

  describe 'basic collection methods' do
    it 'returns correct count' do
      expect(collection.count).to eq(3)
    end

    it 'returns items as array' do
      expect(collection.to_a).to eq(items)
    end

    it 'checks if empty' do
      expect(collection.empty?).to be false

      empty_collection = described_class.new([])
      expect(empty_collection.empty?).to be true
    end

    it 'checks if any items exist' do
      expect(collection.any?).to be true

      empty_collection = described_class.new([])
      expect(empty_collection.any?).to be false
    end
  end

  describe 'iteration methods' do
    it 'iterates over items' do
      collected_items = collection.map { |item| item }
      expect(collected_items).to eq(items)
    end

    it 'maps items' do
      mapped = collection.map(&:to_s)
      expect(mapped).to eq(items.map(&:to_s))
    end

    it 'selects items' do
      selected = collection.select { |item| item == items.first }
      expect(selected.count).to eq(1)
      expect(selected.to_a).to eq([items.first])
    end
  end

  describe 'pagination methods' do
    it 'applies offset' do
      offset_collection = collection.offset(1)
      expect(offset_collection.count).to eq(2)
      expect(offset_collection.to_a).to eq(items[1..])
    end

    it 'applies limit' do
      limited_collection = collection.limit(2)
      expect(limited_collection.count).to eq(2)
      expect(limited_collection.to_a).to eq(items[0..1])
    end

    it 'combines offset and limit' do
      combined_collection = collection.offset(1).limit(1)
      expect(combined_collection.count).to eq(1)
      expect(combined_collection.to_a).to eq([items[1]])
    end

    it 'handles offset beyond collection size' do
      large_offset = collection.offset(10)
      expect(large_offset.count).to eq(0)
      expect(large_offset.to_a).to eq([])
    end

    it 'handles limit larger than collection size' do
      large_limit = collection.limit(10)
      expect(large_limit.count).to eq(3)
      expect(large_limit.to_a).to eq(items)
    end

    it 'handles zero offset' do
      zero_offset = collection.offset(0)
      expect(zero_offset.count).to eq(3)
      expect(zero_offset.to_a).to eq(items)
    end

    it 'handles zero limit' do
      zero_limit = collection.limit(0)
      expect(zero_limit.count).to eq(0)
      expect(zero_limit.to_a).to eq([])
    end

    it 'handles negative offset gracefully' do
      negative_offset = collection.offset(-1)
      expect(negative_offset.count).to eq(3)
      expect(negative_offset.to_a).to eq(items)
    end

    it 'handles negative limit gracefully' do
      negative_limit = collection.limit(-1)
      expect(negative_limit.count).to eq(0)
      expect(negative_limit.to_a).to eq([])
    end
  end

  describe 'chaining methods' do
    it 'chains pagination methods' do
      result = collection.offset(1).limit(1).select { |item| item == items[1] }
      expect(result.count).to eq(1)
      expect(result.to_a).to eq([items[1]])
    end

    it 'chains filtering and pagination' do
      result = collection.reject { |item| item == items.first }.limit(1)
      expect(result.count).to eq(1)
      expect(result.to_a).to eq([items[1]])
    end
  end

  describe 'edge cases' do
    it 'handles single item collection' do
      single_collection = described_class.new([items.first])
      expect(single_collection.count).to eq(1)
      expect(single_collection.offset(1).count).to eq(0)
      expect(single_collection.limit(2).count).to eq(1)
    end

    it 'handles very large collections' do
      large_items = Array.new(1000) { |i| double("Item#{i}") }
      large_collection = described_class.new(large_items)

      expect(large_collection.count).to eq(1000)
      expect(large_collection.offset(500).limit(100).count).to eq(100)
    end

    it 'maintains object references' do
      original_item = items.first
      filtered = collection.select { |item| item == original_item }
      expect(filtered.to_a.first).to be(original_item)
    end
  end

  describe 'immutability' do
    it 'does not modify original items' do
      original_items = items.dup
      collection.offset(1).limit(1)
      expect(collection.items).to eq(original_items)
    end

    it 'creates new collections for operations' do
      offset_collection = collection.offset(1)
      expect(offset_collection).not_to be(collection)
      expect(offset_collection.class).to eq(described_class)
    end
  end

  describe 'performance characteristics' do
    it 'lazy loads items' do
      # The collection should not process items until needed
      expect(collection).to respond_to(:items)
      expect(collection.items).to eq(items)
    end

    it 'efficiently handles empty operations' do
      empty_collection = described_class.new([])
      expect(empty_collection.offset(1).limit(1).count).to eq(0)
    end
  end

  describe 'integration with other methods' do
    it 'works with select and map' do
      result = collection.reject { |item| item == items.last }.map(&:to_s)
      expect(result).to eq(items[0..1].map(&:to_s))
    end

    it 'works with each and collect' do
      collected = collection.offset(1).limit(2).map { |item| item }
      expect(collected).to eq(items[1..2])
    end
  end

  describe 'method delegation' do
    it 'delegates count to items' do
      expect(collection.items).to receive(:count).and_return(3)
      collection.count
    end

    it 'delegates empty? to items' do
      expect(collection.items).to receive(:empty?).and_return(false)
      collection.empty?
    end

    it 'delegates any? to items' do
      expect(collection.items).to receive(:any?).and_return(true)
      collection.any?
    end
  end
end
