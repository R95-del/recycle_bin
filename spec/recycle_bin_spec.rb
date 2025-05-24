# frozen_string_literal: true

RSpec.describe RecycleBin do
  it 'has a version number' do
    expect(RecycleBin::VERSION).not_to be nil
  end

  it 'provides a SoftDeletable module' do
    expect(RecycleBin::SoftDeletable).to be_a(Module)
  end

  describe RecycleBin::SoftDeletable do
    let(:model) { TestModel.create(name: 'Test Item') }

    describe '#soft_delete' do
      it 'marks record as deleted' do
        expect { model.soft_delete }.to change { model.deleted? }.from(false).to(true)
      end

      it 'sets deleted_at timestamp' do
        model.soft_delete
        expect(model.deleted_at).to be_present
      end
    end

    describe '#restore' do
      before { model.soft_delete }

      it 'unmarks record as deleted' do
        expect { model.restore }.to change { model.deleted? }.from(true).to(false)
      end

      it 'clears deleted_at timestamp' do
        model.restore
        expect(model.deleted_at).to be_nil
      end
    end

    describe 'scopes' do
      let!(:active_model) { TestModel.create(name: 'Active') }
      let!(:deleted_model) { TestModel.create(name: 'Deleted') }

      before { deleted_model.soft_delete }

      it 'default scope excludes deleted records' do
        expect(TestModel.all).to include(active_model)
        expect(TestModel.all).not_to include(deleted_model)
      end

      it 'deleted scope includes only deleted records' do
        expect(TestModel.deleted).to include(deleted_model)
        expect(TestModel.deleted).not_to include(active_model)
      end

      it 'with_deleted scope includes all records' do
        expect(TestModel.with_deleted).to include(active_model)
        expect(TestModel.with_deleted).to include(deleted_model)
      end
    end

    describe '#destroy' do
      it 'soft deletes instead of hard deleting' do
        model.save! # Ensure model is persisted
        initial_count = TestModel.with_deleted.count
        model.destroy
        expect(TestModel.with_deleted.count).to eq(initial_count)
        expect(model.deleted?).to be true
      end
    end

    describe '#recyclable_title' do
      it 'returns the name when available' do
        expect(model.recyclable_title).to eq('Test Item')
      end

      it 'falls back to class name and id when name not available' do
        model.update_column(:name, nil)
        expect(model.recyclable_title).to eq("TestModel ##{model.id}")
      end
    end
  end
end
