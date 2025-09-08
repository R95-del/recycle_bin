# frozen_string_literal: true

RSpec.describe RecycleBin do
  # Reset configuration before each test
  before(:each) do
    RecycleBin.configuration = nil
  end

  it 'has a version number' do
    expect(RecycleBin::VERSION).not_to be nil
    expect(RecycleBin::VERSION).to eq('1.2.0')
  end

  describe '.config' do
    it 'returns a configuration object' do
      expect(RecycleBin.config).to be_a(RecycleBin::Configuration)
    end

    it 'has default values' do
      config = RecycleBin.config
      expect(config.enable_web_interface).to be true
      expect(config.items_per_page).to eq(25)
      expect(config.max_items_per_page).to eq(1000)
      expect(config.ui_theme).to eq('default')
      expect(config.enable_export).to be true
      expect(config.export_formats).to eq(%w[csv json])
    end
  end

  describe '.configure' do
    it 'allows configuration with a block' do
      RecycleBin.configure do |config|
        config.items_per_page = 50
        config.enable_export = false
      end

      expect(RecycleBin.config.items_per_page).to eq(50)
      expect(RecycleBin.config.enable_export).to be false
    end

    it 'creates configuration if none exists' do
      expect(RecycleBin.configuration).to be_nil
      RecycleBin.configure do |config|
        config.items_per_page = 30
      end
      expect(RecycleBin.configuration).to be_a(RecycleBin::Configuration)
    end

    it 'allows chaining configuration' do
      config = RecycleBin.configure do |c|
        c.items_per_page = 40
      end
      expect(config).to be_a(RecycleBin::Configuration)
      expect(config.items_per_page).to eq(40)
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

    context 'when Rails is available but no application' do
      before do
        stub_const('Rails', double('Rails', application: nil)) if defined?(Rails)
      end

      it 'returns empty hash' do
        expect(RecycleBin.stats).to eq({})
      end
    end
  end

  describe 'configuration validation' do
    let(:config) { RecycleBin::Configuration.new }

    it 'validates configuration correctly' do
      expect(config.valid?).to be true
    end

    it 'validates search settings' do
      config.search_settings[:min_search_length] = 10
      config.search_settings[:max_search_length] = 5
      expect(config.valid?).to be false
      expect(config.errors).to include('min_search_length cannot be greater than max_search_length')
    end

    it 'validates export settings' do
      config.export_settings[:max_export_items] = 0
      expect(config.valid?).to be false
      expect(config.errors).to include('max_export_items must be positive')
    end

    it 'validates basic settings' do
      config.items_per_page = 0
      expect(config.valid?).to be false
      expect(config.errors).to include('items_per_page must be positive')
    end

    it 'validates max_items_per_page relationship' do
      config.items_per_page = 50
      config.max_items_per_page = 25
      expect(config.valid?).to be false
      expect(config.errors).to include('max_items_per_page cannot be less than items_per_page')
    end
  end

  describe 'configuration methods' do
    let(:config) { RecycleBin::Configuration.new }

    describe 'search configuration' do
      it 'allows setting search configuration' do
        config.enable_full_text_search = false
        config.searchable_fields = %w[title content]
        config.max_search_length = 200
        config.search_timeout = 60.seconds

        expect(config.search_config[:enable_full_text_search]).to be false
        expect(config.search_config[:searchable_fields]).to eq(%w[title content])
        expect(config.search_config[:max_search_length]).to eq(200)
        expect(config.search_config[:search_timeout]).to eq(60.seconds)
      end
    end

    describe 'export configuration' do
      it 'allows setting export configuration' do
        config.enable_csv_export = false
        config.enable_json_export = false
        config.max_export_items = 5000
        config.export_timeout = 10.minutes

        expect(config.export_config[:enable_csv_export]).to be false
        expect(config.export_config[:enable_json_export]).to be false
        expect(config.export_config[:max_export_items]).to eq(5000)
        expect(config.export_config[:export_timeout]).to eq(10.minutes)
      end
    end

    describe 'authorization' do
      it 'allows setting authorization method' do
        auth_proc = proc { current_user&.admin? }
        config.authorize_with(&auth_proc)
        expect(config.authorization_method).to eq(auth_proc)
      end

      it 'has default authorization method' do
        expect(config.authorization_method.call).to be true
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
          expect(stats[:deleted_today]).to be_a(Integer)
          expect(stats[:deleted_this_week]).to be_a(Integer)
        end
      end

      describe '.models_with_soft_delete' do
        it 'includes models with deleted_at column and soft delete capability' do
          models = RecycleBin.models_with_soft_delete
          expect(models).to be_an(Array)
          # In test environment, should find TestModel
          expect(models).to include('TestModel')
        end

        it 'filters out abstract classes' do
          # Create an abstract class
          abstract_class = Class.new(ActiveRecord::Base) do
            self.abstract_class = true
            include RecycleBin::SoftDeletable
          end

          models = RecycleBin.models_with_soft_delete
          expect(models).not_to include(abstract_class.name)
        end

        it 'filters out models without tables' do
          # Create a model without a table
          no_table_class = Class.new(ActiveRecord::Base) do
            include RecycleBin::SoftDeletable
          end

          # Mock table_exists? to return false
          allow(no_table_class).to receive(:table_exists?).and_return(false)

          models = RecycleBin.models_with_soft_delete
          expect(models).not_to include(no_table_class.name)
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

        it 'handles errors gracefully' do
          # Mock a model that raises an error
          allow(TestModel).to receive(:deleted).and_raise(StandardError, 'Database error')

          count = RecycleBin.count_deleted_items
          expect(count).to eq(0)
        end
      end

      describe '.count_deleted_items_today' do
        it 'counts items deleted today' do
          # Clear any existing records first
          TestModel.with_deleted.delete_all

          # Create and delete records at different times
          old_record = TestModel.create(name: 'Old')
          old_record.soft_delete
          old_record.update_column(:deleted_at, 2.days.ago)

          recent_record = TestModel.create(name: 'Recent')
          recent_record.soft_delete

          count = RecycleBin.count_deleted_items_today
          expect(count).to be >= 1
        end
      end

      describe '.count_deleted_items_this_week' do
        it 'counts items deleted this week' do
          # Clear any existing records first
          TestModel.with_deleted.delete_all

          # Create and delete records at different times
          old_record = TestModel.create(name: 'Old')
          old_record.soft_delete
          old_record.update_column(:deleted_at, 2.weeks.ago)

          recent_record = TestModel.create(name: 'Recent')
          recent_record.soft_delete

          count = RecycleBin.count_deleted_items_this_week
          expect(count).to be >= 1
        end
      end

      describe '.all_deleted_items' do
        it 'returns all deleted items with ordering' do
          # Clear any existing records first
          TestModel.with_deleted.delete_all

          # Create and delete records
          records = []
          3.times do |i|
            record = TestModel.create(name: "Test #{i}")
            record.soft_delete
            records << record
          end

          all_items = RecycleBin.all_deleted_items(order_by: :name, order_direction: :asc)
          expect(all_items).to be_an(Array)
          expect(all_items.count).to be >= 3
        end

        it 'applies limit and offset' do
          # Clear any existing records first
          TestModel.with_deleted.delete_all

          # Create and delete records
          5.times do |i|
            record = TestModel.create(name: "Test #{i}")
            record.soft_delete
          end

          limited_items = RecycleBin.all_deleted_items(limit: 2, offset: 1)
          expect(limited_items.count).to eq(2)
        end

        it 'handles errors gracefully' do
          # Mock a model that raises an error
          allow(TestModel).to receive(:deleted).and_raise(StandardError, 'Database error')

          items = RecycleBin.all_deleted_items
          expect(items).to eq([])
        end
      end

      describe 'model discovery edge cases' do
        it 'handles models without deleted_at column' do
          # Create a model without deleted_at
          no_deleted_at_class = Class.new(ActiveRecord::Base) do
            include RecycleBin::SoftDeletable
          end

          # Mock column_names to exclude deleted_at
          allow(no_deleted_at_class).to receive(:column_names).and_return(%w[id name])

          models = RecycleBin.models_with_soft_delete
          expect(models).not_to include(no_deleted_at_class.name)
        end

        it 'handles models without soft delete capability' do
          # Create a model without soft delete methods
          no_soft_delete_class = Class.new(ActiveRecord::Base) do
            include RecycleBin::SoftDeletable
          end

          # Mock respond_to? to return false for :deleted
          allow(no_soft_delete_class).to receive(:respond_to?).with(:deleted).and_return(false)

          models = RecycleBin.models_with_soft_delete
          expect(models).not_to include(no_soft_delete_class.name)
        end
      end
    end
  else
    describe 'without ActiveRecord' do
      it 'handles missing ActiveRecord gracefully' do
        expect(RecycleBin.models_with_soft_delete).to eq([])
        expect(RecycleBin.count_deleted_items).to eq(0)
        expect(RecycleBin.count_deleted_items_today).to eq(0)
        expect(RecycleBin.count_deleted_items_this_week).to eq(0)
        expect(RecycleBin.all_deleted_items).to eq([])
      end

      it 'handles missing Rails gracefully' do
        stub_const('Rails', nil) if defined?(Rails)
        expect(RecycleBin.rails_application_available?).to be false
        expect(RecycleBin.stats).to eq({})
      end
    end
  end

  describe 'error handling' do
    it 'handles configuration errors gracefully' do
      # Test that configuration errors don't crash the system
      expect { RecycleBin.config.valid? }.not_to raise_error
    end

    it 'provides meaningful error messages' do
      config = RecycleBin::Configuration.new
      config.items_per_page = -1

      expect(config.valid?).to be false
      expect(config.errors).to include('items_per_page must be positive')
    end
  end

  describe 'performance considerations' do
    it 'caches configuration' do
      config1 = RecycleBin.config
      config2 = RecycleBin.config
      expect(config1).to be(config2)
    end

    it 'lazy loads configuration' do
      expect(RecycleBin.configuration).to be_nil
      config = RecycleBin.config
      expect(RecycleBin.configuration).to be(config)
    end
  end
end
