# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/services/recycle_bin/cleanup_service'

RSpec.describe RecycleBin::CleanupService do
  let(:cutoff_date) { 30.days.ago }
  let(:service) { described_class.new(cutoff_date: cutoff_date, dry_run: false) }
  let(:dry_run_service) { described_class.new(cutoff_date: cutoff_date, dry_run: true) }

  before do
    # Set up Rails mock
    unless defined?(Rails) && Rails.respond_to?(:application)
      rails_mock = double('Rails')
      app_mock = double('Application')
      logger_mock = double('Logger')

      allow(logger_mock).to receive(:info)
      allow(logger_mock).to receive(:error)
      allow(logger_mock).to receive(:debug)

      allow(app_mock).to receive(:eager_load!)
      allow(rails_mock).to receive(:application).and_return(app_mock)
      allow(rails_mock).to receive(:logger).and_return(logger_mock)

      stub_const('Rails', rails_mock)
    end
  end

  describe '#initialize' do
    it 'sets cutoff_date from parameter' do
      expect(service.cutoff_date).to eq(cutoff_date)
    end

    it 'sets dry_run mode' do
      expect(dry_run_service.dry_run).to be true
      expect(service.dry_run).to be false
    end

    it 'uses default batch size' do
      expect(service.batch_size).to eq(100)
    end

    it 'allows custom batch size' do
      custom_service = described_class.new(batch_size: 50)
      expect(custom_service.batch_size).to eq(50)
    end

    it 'calculates cutoff_date from config when not provided' do
      RecycleBin.configure do |config|
        config.auto_cleanup_after = 45.days
      end

      service_without_date = described_class.new
      expect(service_without_date.cutoff_date).to be_within(1.second).of(45.days.ago)
    end

    it 'returns nil cutoff_date when config not set' do
      RecycleBin.configure do |config|
        config.auto_cleanup_after = nil
      end

      service_without_date = described_class.new
      expect(service_without_date.cutoff_date).to be_nil
    end
  end

  if defined?(ActiveRecord) && defined?(TestModel)
    describe '#perform', :ar do
      before do
        # Clear existing test data
        TestModel.with_deleted.delete_all

        # Configure cleanup
        RecycleBin.configure do |config|
          config.auto_cleanup_after = 30.days
        end
      end

      context 'when cleanup is not configured' do
        before do
          RecycleBin.configure do |config|
            config.auto_cleanup_after = nil
          end
        end

        it 'returns error when cutoff_date is nil' do
          service = described_class.new(cutoff_date: nil)

          results = service.perform

          expect(results[:success]).to be false
          expect(results[:errors]).to include('Auto-cleanup is not configured')
        end
      end

      context 'with old deleted items' do
        let!(:old_item1) do
          item = TestModel.create(name: 'Old Item 1')
          item.soft_delete
          item.update_column(:deleted_at, 60.days.ago)
          item
        end

        let!(:old_item2) do
          item = TestModel.create(name: 'Old Item 2')
          item.soft_delete
          item.update_column(:deleted_at, 45.days.ago)
          item
        end

        let!(:recent_item) do
          item = TestModel.create(name: 'Recent Item')
          item.soft_delete
          item.update_column(:deleted_at, 15.days.ago)
          item
        end

        it 'deletes only items older than cutoff date' do
          results = service.perform

          expect(results[:success]).to be true
          expect(results[:deleted_count]).to eq(2)

          # Verify old items are permanently deleted
          expect(TestModel.with_deleted.find_by(id: old_item1.id)).to be_nil
          expect(TestModel.with_deleted.find_by(id: old_item2.id)).to be_nil

          # Verify recent item still exists
          expect(TestModel.with_deleted.find_by(id: recent_item.id)).not_to be_nil
        end

        it 'tracks models processed' do
          results = service.perform

          expect(results[:models_processed]).to have_key('TestModel')
          expect(results[:models_processed]['TestModel']).to eq(2)
        end

        it 'includes cutoff_date in results' do
          results = service.perform

          expect(results[:cutoff_date]).to eq(cutoff_date)
        end
      end

      context 'in dry run mode' do
        let!(:old_item) do
          item = TestModel.create(name: 'Old Item')
          item.soft_delete
          item.update_column(:deleted_at, 60.days.ago)
          item
        end

        it 'does not actually delete items' do
          results = dry_run_service.perform

          expect(results[:success]).to be true
          expect(results[:deleted_count]).to eq(1)
          expect(results[:dry_run]).to be true

          # Verify item still exists
          expect(TestModel.with_deleted.find_by(id: old_item.id)).not_to be_nil
        end

        it 'reports what would be deleted' do
          results = dry_run_service.perform

          expect(results[:models_processed]['TestModel']).to eq(1)
        end
      end

      context 'with no items to cleanup' do
        it 'handles empty result gracefully' do
          results = service.perform

          expect(results[:success]).to be true
          expect(results[:deleted_count]).to eq(0)
          expect(results[:models_processed]).to be_empty
        end
      end

      context 'with batch processing' do
        let(:batch_service) { described_class.new(cutoff_date: cutoff_date, batch_size: 2) }

        before do
          # Create 5 old items
          5.times do |i|
            item = TestModel.create(name: "Batch Item #{i}")
            item.soft_delete
            item.update_column(:deleted_at, 60.days.ago)
          end
        end

        it 'processes items in batches' do
          results = batch_service.perform

          expect(results[:success]).to be true
          expect(results[:deleted_count]).to eq(5)
        end
      end

      context 'with errors during deletion' do
        let!(:problematic_item) do
          item = TestModel.create(name: 'Problematic Item')
          item.soft_delete
          item.update_column(:deleted_at, 60.days.ago)
          item
        end

        it 'continues processing after individual errors' do
          # Simulate an error for one item
          allow_any_instance_of(TestModel).to receive(:destroy!).and_raise(StandardError, 'Delete failed')

          results = service.perform

          # Should still report the attempt
          expect(results[:errors]).not_to be_empty
        end
      end
    end
  end

  describe 'error handling' do
    it 'handles general errors gracefully' do
      allow(RecycleBin).to receive(:models_with_soft_delete).and_raise(StandardError, 'Database error')

      results = service.perform

      expect(results[:success]).to be false
      expect(results[:errors]).not_to be_empty
    end
  end
end
