# frozen_string_literal: true

require 'spec_helper'

# Only run these tests if ActiveRecord and TestModel are available
if defined?(ActiveRecord) && defined?(TestModel)
  RSpec.describe RecycleBin::SoftDeletable do
    let(:test_record) { TestModel.create(name: 'Test Record') }

    describe '#soft_delete' do
      it 'marks record as deleted' do
        expect { test_record.soft_delete }.to change { test_record.deleted? }.from(false).to(true)
      end

      it 'sets deleted_at timestamp' do
        test_record.soft_delete
        expect(test_record.deleted_at).to be_present
      end

      it 'returns true when successful' do
        expect(test_record.soft_delete).to be true
      end

      it 'returns false when already deleted' do
        test_record.soft_delete
        expect(test_record.soft_delete).to be false
      end
    end

    describe '#restore' do
      before { test_record.soft_delete }

      it 'restores deleted record' do
        expect { test_record.restore }.to change { test_record.deleted? }.from(true).to(false)
      end

      it 'clears deleted_at timestamp' do
        test_record.restore
        expect(test_record.deleted_at).to be_nil
      end

      it 'returns true when successful' do
        expect(test_record.restore).to be true
      end
    end

    describe '#deleted?' do
      it 'returns false for active record' do
        expect(test_record.deleted?).to be false
      end

      it 'returns true for deleted record' do
        test_record.soft_delete
        expect(test_record.deleted?).to be true
      end
    end

    describe '#destroy' do
      it 'soft deletes instead of hard deletes' do
        test_record.destroy
        expect(test_record.deleted?).to be true
        expect(TestModel.with_deleted.find(test_record.id)).to eq(test_record)
      end
    end

    describe '#destroy!' do
      it 'permanently deletes the record' do
        id = test_record.id
        test_record.destroy!
        expect { TestModel.with_deleted.find(id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '.deleted scope' do
      let!(:active_record) { TestModel.create(name: 'Active') }
      let!(:deleted_record) { TestModel.create(name: 'Deleted').tap(&:soft_delete) }

      it 'returns only deleted records' do
        expect(TestModel.deleted).to include(deleted_record)
        expect(TestModel.deleted).not_to include(active_record)
      end
    end

    describe '.with_deleted scope' do
      let!(:active_record) { TestModel.create(name: 'Active') }
      let!(:deleted_record) { TestModel.create(name: 'Deleted').tap(&:soft_delete) }

      it 'returns all records including deleted' do
        expect(TestModel.with_deleted).to include(active_record, deleted_record)
      end
    end

    describe '#recyclable_title' do
      it 'returns name when available' do
        expect(test_record.recyclable_title).to eq('Test Record')
      end

      it 'falls back to class name and ID' do
        record = TestModel.create
        expect(record.recyclable_title).to eq("TestModel ##{record.id}")
      end
    end
  end
else
  RSpec.describe 'RecycleBin::SoftDeletable (skipped)' do
    it 'is skipped because ActiveRecord is not available' do
      pending 'ActiveRecord not available in test environment'
    end
  end
end
