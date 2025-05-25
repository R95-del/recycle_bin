# frozen_string_literal: true

RSpec.describe RecycleBin do
  # Reset configuration before each test
  before(:each) do
    RecycleBin.configuration = nil
  end

  it 'has a version number' do
    expect(RecycleBin::VERSION).not_to be nil
    expect(RecycleBin::VERSION).to eq('1.0.0')
  end

  describe '.config' do
    it 'returns a configuration object' do
      expect(RecycleBin.config).to be_a(RecycleBin::Configuration)
    end

    it 'has default values' do
      config = RecycleBin.config
      expect(config.enable_web_interface).to be true
      expect(config.items_per_page).to eq(25)
    end
  end

  describe '.configure' do
    it 'allows configuration with a block' do
      RecycleBin.configure do |config|
        config.items_per_page = 50
      end

      expect(RecycleBin.config.items_per_page).to eq(50)
    end

    it 'creates configuration if none exists' do
      expect(RecycleBin.configuration).to be_nil
      RecycleBin.configure do |config|
        config.items_per_page = 30
      end
      expect(RecycleBin.configuration).to be_a(RecycleBin::Configuration)
    end
  end

  describe '.stats' do
    context 'when Rails is not available' do
      before do
        # Mock Rails not being available
        stub_const('Rails', nil) if defined?(Rails)
        # Clear any existing configuration
        RecycleBin.configuration = nil
      end

      it 'returns empty hash' do
        expect(RecycleBin.stats).to eq({})
      end
    end
  end

  # Only run ActiveRecord tests if it's available
  if defined?(ActiveRecord) && defined?(TestModel)
    describe 'with ActiveRecord', :ar do
      before do
        # Set up proper Rails mock for all ActiveRecord tests
        unless defined?(Rails) && Rails.respond_to?(:application)
          rails_mock = double('Rails')
          app_mock = double('Application')
          allow(app_mock).to receive(:eager_load!)
          allow(rails_mock).to receive(:application).and_return(app_mock)
          stub_const('Rails', rails_mock)
        end
      end

      describe '.stats' do
        it 'returns stats about deleted items' do
          # Create and soft delete a test record
          test_record = TestModel.create(name: 'Test')
          test_record.soft_delete

          stats = RecycleBin.stats
          expect(stats).to be_a(Hash)
          expect(stats[:deleted_items]).to be_a(Integer)
          expect(stats[:deleted_items]).to be >= 0
          expect(stats[:models_with_soft_delete]).to be_an(Array)
        end
      end

      describe '.models_with_soft_delete' do
        it 'includes models with deleted_at column and soft delete capability' do
          models = RecycleBin.models_with_soft_delete
          expect(models).to be_an(Array)
          # In test environment, should find TestModel
          expect(models).to include('TestModel')
        end
      end

      describe '.count_deleted_items' do
        it 'counts deleted items across all models' do
          # Clear any existing records first
          TestModel.with_deleted.delete_all

          # Create and delete some test records
          records = []
          3.times do |i|
            record = TestModel.create(name: "Test #{i}")
            record.soft_delete
            records << record
          end

          # Verify the records are actually deleted
          expect(TestModel.deleted.count).to eq(3)

          # Now test our count method
          count = RecycleBin.count_deleted_items
          expect(count).to be >= 3
        end
      end
    end
  else
    describe 'without ActiveRecord' do
      it 'handles missing ActiveRecord gracefully' do
        expect(RecycleBin.models_with_soft_delete).to eq([])
      end
    end
  end
end
