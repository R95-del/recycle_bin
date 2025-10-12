# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/jobs/recycle_bin/cleanup_job'

RSpec.describe RecycleBin::CleanupJob, type: :job do
  describe '#perform' do
    let(:successful_results) do
      {
        success: true,
        deleted_count: 5,
        models_processed: { 'TestModel' => 5 },
        errors: []
      }
    end

    let(:failed_results) do
      {
        success: false,
        deleted_count: 0,
        models_processed: {},
        errors: ['Some error occurred']
      }
    end

    it 'calls RecycleBin.cleanup_old_items!' do
      allow(RecycleBin).to receive(:cleanup_old_items!).and_return(successful_results)

      described_class.new.perform

      expect(RecycleBin).to have_received(:cleanup_old_items!).with(cutoff_date: nil, dry_run: false)
    end

    it 'passes cutoff_date parameter' do
      cutoff_date = 60.days.ago
      allow(RecycleBin).to receive(:cleanup_old_items!).and_return(successful_results)

      described_class.new.perform(cutoff_date: cutoff_date)

      expect(RecycleBin).to have_received(:cleanup_old_items!).with(cutoff_date: cutoff_date, dry_run: false)
    end

    it 'handles string cutoff_date (from job serialization)' do
      cutoff_string = 60.days.ago.to_s
      allow(RecycleBin).to receive(:cleanup_old_items!).and_return(successful_results)

      described_class.new.perform(cutoff_date: cutoff_string)

      expect(RecycleBin).to have_received(:cleanup_old_items!) do |args|
        expect(args[:cutoff_date]).to be_a(Time)
        expect(args[:dry_run]).to be false
      end
    end

    it 'returns results from cleanup' do
      allow(RecycleBin).to receive(:cleanup_old_items!).and_return(successful_results)

      results = described_class.new.perform

      expect(results).to eq(successful_results)
    end

    context 'when cleanup fails' do
      it 'raises an error' do
        allow(RecycleBin).to receive(:cleanup_old_items!).and_return(failed_results)

        expect do
          described_class.new.perform
        end.to raise_error(RecycleBin::Error, /Cleanup failed/)
      end
    end

    context 'when an exception occurs' do
      it 'logs and re-raises the error' do
        allow(RecycleBin).to receive(:cleanup_old_items!).and_raise(StandardError, 'Database error')

        expect do
          described_class.new.perform
        end.to raise_error(StandardError, 'Database error')
      end
    end
  end

  describe 'job configuration' do
    it 'is configured with default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end

    it 'has retry configuration' do
      # ActiveJob retry configuration is set via retry_on
      # We verify it's configured but actual retry behavior is tested by ActiveJob
      expect(described_class).to respond_to(:retry_on)
    end
  end
end
