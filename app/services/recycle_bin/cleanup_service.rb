# frozen_string_literal: true

module RecycleBin
  # Service class responsible for cleaning up old deleted items
  # Handles the permanent deletion of soft-deleted records that are older
  # than the configured cleanup threshold
  class CleanupService
    attr_reader :cutoff_date, :dry_run, :batch_size, :logger, :results

    # Initialize the cleanup service
    #
    # @param cutoff_date [Time, Date] Items deleted before this date will be cleaned up
    # @param dry_run [Boolean] If true, only simulates cleanup without actually deleting
    # @param batch_size [Integer] Number of items to process in each batch
    # @param logger [Logger] Logger instance for output
    def initialize(cutoff_date: nil, dry_run: false, batch_size: 100, logger: nil)
      @cutoff_date = cutoff_date || calculate_cutoff_date
      @dry_run = dry_run
      @batch_size = batch_size
      @logger = logger || default_logger
      @results = initialize_results
    end

    # Perform the cleanup operation
    #
    # @return [Hash] Results with deleted counts and any errors
    def perform
      return error_result('Auto-cleanup is not configured') if cutoff_date.nil?

      log_info("Starting cleanup #{dry_run ? '(DRY RUN)' : ''}...")
      log_info("Cutoff date: #{cutoff_date}")

      process_all_models

      log_summary

      results
    rescue StandardError => e
      handle_error('Cleanup failed', e)
      results
    end

    private

    def calculate_cutoff_date
      return nil if RecycleBin.config.auto_cleanup_after.nil?

      Time.current - RecycleBin.config.auto_cleanup_after
    end

    def default_logger
      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger
      else
        Logger.new($stdout)
      end
    end

    def initialize_results
      {
        success: true,
        deleted_count: 0,
        models_processed: {},
        errors: [],
        dry_run: dry_run,
        cutoff_date: cutoff_date
      }
    end

    def process_all_models
      RecycleBin.models_with_soft_delete.each do |model_name|
        process_model(model_name)
      rescue StandardError => e
        handle_model_error(model_name, e)
      end
    end

    def process_model(model_name)
      model = model_name.constantize
      return unless model.respond_to?(:deleted)

      old_items = find_old_items(model)
      count = old_items.count

      return if count.zero?

      log_info("Processing #{model_name}: #{count} items to cleanup")

      deleted = dry_run ? count : delete_items(model, old_items)

      results[:models_processed][model_name] = deleted
      results[:deleted_count] += deleted
    end

    def find_old_items(model)
      model.deleted.where('deleted_at < ?', cutoff_date)
    end

    def delete_items(_model, items_relation)
      deleted_count = 0

      items_relation.find_in_batches(batch_size: batch_size) do |batch|
        batch.each do |item|
          delete_item(item)
          deleted_count += 1
        rescue StandardError => e
          handle_item_error(item, e)
        end

        log_debug("Batch processed: #{deleted_count} items deleted so far")
      end

      deleted_count
    end

    def delete_item(item)
      # Use destroy! to permanently delete (bypasses soft delete)
      if item.respond_to?(:destroy!)
        item.destroy!
      else
        # Fallback for items that might not have destroy! implemented
        item.class.unscoped.where(id: item.id).delete_all
      end
    end

    def log_summary
      log_info('=' * 60)
      log_info("Cleanup #{dry_run ? 'simulation ' : ''}complete!")
      log_info("Total items #{dry_run ? 'would be ' : ''}deleted: #{results[:deleted_count]}")

      results[:models_processed].each do |model_name, count|
        log_info("  #{model_name}: #{count}")
      end

      log_info("Errors encountered: #{results[:errors].count}") if results[:errors].any?
      log_info('=' * 60)
    end

    def error_result(message)
      results[:success] = false
      results[:errors] << message
      log_error(message)
      results
    end

    def handle_error(message, error)
      error_message = "#{message}: #{error.message}"
      results[:success] = false
      results[:errors] << error_message
      log_error(error_message)
      log_debug("Backtrace: #{error.backtrace&.first(5)&.join("\n")}")
    end

    def handle_model_error(model_name, error)
      handle_error("Error processing #{model_name}", error)
    end

    def handle_item_error(item, error)
      error_message = "Failed to delete #{item.class.name}##{item.id}: #{error.message}"
      results[:errors] << error_message
      log_error(error_message)
    end

    def log_info(message)
      logger&.info("[RecycleBin::Cleanup] #{message}")
    end

    def log_error(message)
      logger&.error("[RecycleBin::Cleanup] #{message}")
    end

    def log_debug(message)
      logger&.debug("[RecycleBin::Cleanup] #{message}")
    end
  end
end
