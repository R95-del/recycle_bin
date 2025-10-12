# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :recycle_bin do
  desc 'Clean up old deleted items based on auto_cleanup_after configuration'
  task cleanup: :environment do
    print_header('RecycleBin Cleanup')

    if RecycleBin.config.auto_cleanup_after.nil?
      print_warning('⚠️  auto_cleanup_after is not configured')
      print_info('Configure it in config/initializers/recycle_bin.rb:')
      print_info('  config.auto_cleanup_after = 30.days')
      print_info('')
      print_info('Or specify a custom duration:')
      print_info('  rake recycle_bin:cleanup[30]  # Delete items older than 30 days')
      exit 0
    end

    # Check if days argument is provided
    cutoff_date = if ENV['DAYS']
                    days = ENV['DAYS'].to_i
                    days.days.ago
                  end

    print_cleanup_info(cutoff_date)

    if confirm_cleanup?
      results = RecycleBin.cleanup_old_items!(cutoff_date: cutoff_date, dry_run: false)
      print_results(results)
    else
      print_warning('Cleanup cancelled')
    end
  end

  desc 'Preview cleanup without actually deleting items (dry run)'
  task 'cleanup:dry_run': :environment do
    print_header('RecycleBin Cleanup (DRY RUN)')

    cutoff_date = if ENV['DAYS']
                    days = ENV['DAYS'].to_i
                    days.days.ago
                  end

    print_cleanup_info(cutoff_date)
    print_warning('🔍 DRY RUN MODE - No items will be deleted')
    puts ''

    results = RecycleBin.cleanup_old_items!(cutoff_date: cutoff_date, dry_run: true)
    print_results(results)
  end

  desc 'Show cleanup status and pending deletions'
  task status: :environment do
    print_header('RecycleBin Cleanup Status')

    status = RecycleBin.cleanup_status

    if status[:enabled]
      print_success('✅ Auto-cleanup is ENABLED')
      puts ''
      print_info('Configuration:')
      print_info("  Cleanup after: #{format_duration(status[:auto_cleanup_after])}")
      print_info("  Cutoff date: #{status[:cutoff_date].strftime('%Y-%m-%d %H:%M:%S')}")
      puts ''
      print_info("Items pending deletion: #{status[:items_pending_deletion]}")

      if status[:items_pending_deletion].positive?
        print_warning("⚠️  #{status[:items_pending_deletion]} items will be deleted on next cleanup")
        print_info('Run: rake recycle_bin:cleanup:dry_run to preview')
      else
        print_success('✨ No items pending deletion')
      end
    else
      print_warning('⚠️  Auto-cleanup is DISABLED')
      print_info('Enable it in config/initializers/recycle_bin.rb:')
      print_info('  config.auto_cleanup_after = 30.days')
    end

    puts ''
  end

  desc 'Show detailed statistics about deleted items'
  task stats: :environment do
    print_header('RecycleBin Statistics')

    stats = RecycleBin.stats
    models = RecycleBin.models_with_soft_delete

    print_info("Total deleted items: #{stats[:deleted_items]}")
    print_info("Deleted today: #{stats[:deleted_today]}")
    print_info("Deleted this week: #{stats[:deleted_this_week]}")
    puts ''

    if models.any?
      print_info('Models with soft delete:')
      models.each do |model_name|
        model = model_name.constantize
        count = model.deleted.count
        print_info("  #{model_name}: #{count} deleted items")
      end
    else
      print_warning('No models with soft delete found')
    end

    puts ''

    # Show cleanup status
    status = RecycleBin.cleanup_status
    if status[:enabled]
      print_info("Auto-cleanup: ENABLED (#{format_duration(RecycleBin.config.auto_cleanup_after)})")
      print_info("Items pending cleanup: #{status[:items_pending_deletion]}")
    else
      print_info('Auto-cleanup: DISABLED')
    end

    puts ''
  end

  # Helper methods
  def print_header(title)
    puts ''
    puts '=' * 60
    puts title.center(60)
    puts '=' * 60
    puts ''
  end

  def print_success(message)
    puts "\e[32m#{message}\e[0m" # Green
  end

  def print_warning(message)
    puts "\e[33m#{message}\e[0m" # Yellow
  end

  def print_error(message)
    puts "\e[31m#{message}\e[0m" # Red
  end

  def print_info(message)
    puts message
  end

  def print_cleanup_info(cutoff_date)
    actual_cutoff = cutoff_date || RecycleBin.calculate_cleanup_cutoff_date

    return unless actual_cutoff

    print_info("Cutoff date: #{actual_cutoff.strftime('%Y-%m-%d %H:%M:%S')}")
    print_info("Items to be deleted: #{RecycleBin.items_pending_cleanup(actual_cutoff)}")
    puts ''
  end

  def confirm_cleanup?
    return true unless $stdin.tty? # Non-interactive mode (CI, cron)

    print '⚠️  This will PERMANENTLY delete items. Continue? (y/N): '
    response = $stdin.gets.chomp
    %w[y yes].include?(response.downcase)
  end

  def print_results(results)
    puts ''
    puts '=' * 60

    if results[:success]
      action = results[:dry_run] ? 'would be deleted' : 'deleted'
      print_success("✅ Cleanup #{results[:dry_run] ? 'preview ' : ''}complete!")
      puts ''
      print_info("Total items #{action}: #{results[:deleted_count]}")

      if results[:models_processed].any?
        puts ''
        print_info('Breakdown by model:')
        results[:models_processed].each do |model_name, count|
          print_info("  #{model_name}: #{count}")
        end
      end
    else
      print_error('❌ Cleanup failed!')
    end

    if results[:errors].any?
      puts ''
      print_error('Errors encountered:')
      results[:errors].each do |error|
        print_error("  - #{error}")
      end
    end

    puts '=' * 60
    puts ''
  end

  def format_duration(duration)
    return 'N/A' if duration.nil?

    days = (duration / 1.day).to_i
    return "#{days} days" if days.positive?

    hours = (duration / 1.hour).to_i
    return "#{hours} hours" if hours.positive?

    minutes = (duration / 1.minute).to_i
    "#{minutes} minutes"
  end
end
# rubocop:enable Metrics/BlockLength
