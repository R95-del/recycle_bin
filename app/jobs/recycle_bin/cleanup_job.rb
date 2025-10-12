# frozen_string_literal: true

module RecycleBin
  # Background job for cleaning up old deleted items
  # This job can be scheduled using any job scheduler (Sidekiq-cron, whenever, etc.)
  #
  # @example Enqueue the job
  #   RecycleBin::CleanupJob.perform_later
  #
  # @example Enqueue with custom cutoff date
  #   RecycleBin::CleanupJob.perform_later(cutoff_date: 60.days.ago)
  #
  # @example Schedule with Sidekiq-cron
  #   Sidekiq::Cron::Job.create(
  #     name: 'RecycleBin cleanup',
  #     cron: '0 2 * * *', # Daily at 2am
  #     class: 'RecycleBin::CleanupJob'
  #   )
  class CleanupJob < ActiveJob::Base
    queue_as :default

    # Retry with exponential backoff on failures
    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    # Perform the cleanup operation
    #
    # @param cutoff_date [Time, String] Optional cutoff date for cleanup
    def perform(cutoff_date: nil)
      # Convert string to Time if needed (for job serialization)
      cutoff_date = Time.parse(cutoff_date) if cutoff_date.is_a?(String)

      log_info('Starting scheduled cleanup...')

      results = RecycleBin.cleanup_old_items!(cutoff_date: cutoff_date, dry_run: false)

      if results[:success]
        log_info("Cleanup completed successfully. Deleted #{results[:deleted_count]} items.")
        log_models_processed(results[:models_processed])
      else
        log_error('Cleanup failed')
        log_errors(results[:errors])
        raise RecycleBin::Error, "Cleanup failed: #{results[:errors].join(', ')}"
      end

      results
    rescue StandardError => e
      log_error("Cleanup job failed: #{e.message}")
      raise
    end

    private

    def log_info(message)
      logger.info("[RecycleBin::CleanupJob] #{message}")
    end

    def log_error(message)
      logger.error("[RecycleBin::CleanupJob] #{message}")
    end

    def log_models_processed(models)
      return if models.empty?

      models.each do |model_name, count|
        log_info("  #{model_name}: #{count} items deleted")
      end
    end

    def log_errors(errors)
      return if errors.empty?

      errors.each do |error|
        log_error("  - #{error}")
      end
    end

    def logger
      @logger ||= if defined?(Rails)
                    Rails.logger
                  else
                    Logger.new($stdout)
                  end
    end
  end
end
