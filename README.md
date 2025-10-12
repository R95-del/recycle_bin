<div align="center">
  <h1>🗑️ RecycleBin</h1>
  <img src="https://raw.githubusercontent.com/R95-del/recycle_bin/main/docs/logo.svg" alt="RecycleBin Logo" width="120" height="120">
  <p><strong>Elegant soft delete solution for Ruby on Rails applications</strong></p>
  <p>
    <a href="https://rubygems.org/gems/recycle_bin">
      <img src="https://img.shields.io/gem/v/recycle_bin?style=for-the-badge&logo=rubygems&logoColor=white&color=667eea" alt="Gem Version">
    </a>
    <a href="https://github.com/R95-del/recycle_bin/actions">
      <img src="https://img.shields.io/github/actions/workflow/status/R95-del/recycle_bin/main.yml?style=for-the-badge&logo=github&logoColor=white&color=28a745" alt="CI Status">
    </a>
    <a href="https://github.com/R95-del/recycle_bin/discussions">
      <img src="https://img.shields.io/github/discussions/R95-del/recycle_bin?style=for-the-badge&logo=github&logoColor=white&color=007bff" alt="GitHub Discussions">
    </a>
    <a href="https://github.com/R95-del/recycle_bin/blob/main/LICENSE.txt">
      <img src="https://img.shields.io/github/license/R95-del/recycle_bin?style=for-the-badge&color=764ba2" alt="MIT License">
    </a>
  </p>
  <p>
    <a href="https://recyclebin.vercel.app">📖 Documentation</a> •
    <a href="https://github.com/R95-del/recycle_bin/blob/main/CHANGELOG.md">📋 Changelog</a> •
    <a href="https://github.com/R95-del/recycle_bin/discussions">💬 Discussions</a> •
    <a href="https://rubygems.org/gems/recycle_bin">💎 RubyGems</a>
  </p>
</div>

A simple and elegant soft delete solution for Rails applications with a beautiful web interface to manage your deleted records.

**RecycleBin** provides a "trash can" or "recycle bin" functionality where deleted records are marked as deleted instead of being permanently removed from your database. You can easily restore them or permanently delete them through a clean web interface.

## 🆕 What's New in Version 1.3.0

🗑️ **Scheduled Auto-Cleanup** - Automatically delete old trash items with flexible scheduling
⏰ **Rake Tasks** - Manual cleanup with `rake recycle_bin:cleanup` and dry-run mode
🤖 **Background Job Support** - Optional ActiveJob for scheduled execution
📅 **Smart Scheduling** - Works with ANY scheduler (Whenever, Sidekiq-cron, GoodJob, Heroku, etc.)
🔍 **Status Monitoring** - Check cleanup status and pending deletions
🛡️ **Safety First** - Dry-run mode, confirmations, and comprehensive logging

## Features ✨

### Core Features
- **Soft Delete**: Records are marked as deleted instead of being permanently removed
- **Web Interface**: Beautiful, responsive dashboard to view and manage deleted items
- **Easy Integration**: Simple module inclusion in your models
- **Bulk Operations**: Restore or permanently delete multiple items at once
- **Statistics Dashboard**: Overview of your deleted items with charts

### Search & Filtering
- **🔍 Enhanced Search**: Full-text search across all fields with highlighting
- **📊 Advanced Filtering**: Filter by model type, time period, user, size, and date ranges
- **🎯 Priority-Based Search**: Smart matching with exact, starts-with, and contains logic

### Auto-Cleanup (NEW in v1.3.0)
- **🗑️ Scheduled Cleanup**: Automatically delete old trash items based on age
- **⏰ Manual Control**: Run cleanup anytime with rake tasks
- **🔍 Dry-Run Mode**: Preview what will be deleted before committing
- **🤖 Background Jobs**: Optional ActiveJob support for async processing
- **📅 Flexible Scheduling**: Works with ANY scheduler (cron, Whenever, Sidekiq-cron, etc.)
- **🛡️ Safety Features**: Confirmations, logging, and error recovery

### Additional Features
- **📤 Export Functionality**: Export to CSV and JSON formats
- **Rails Generators**: Automated setup with generators
- **Configurable**: Flexible configuration options
- **📝 Comprehensive Logging**: Detailed error tracking and audit trails

## Installation 📦

Add this line to your application's Gemfile:

```ruby
gem 'recycle_bin', '~> 1.2'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install recycle_bin
```

## Quick Setup 🚀

### 1. Run the install generator

```bash
$ rails generate recycle_bin:install
```

This will:
- Create a configuration file at `config/initializers/recycle_bin.rb`
- Add the mount point to your routes
- Display setup instructions

### 2. Add deleted_at column to your models

For each model you want to soft delete, run:

```bash
$ rails generate recycle_bin:add_deleted_at ModelName
```

For example:
```bash
$ rails generate recycle_bin:add_deleted_at User
$ rails generate recycle_bin:add_deleted_at Post
$ rails generate recycle_bin:add_deleted_at Comment
```

This generates a migration to add the `deleted_at` column and index.

### 3. Run the migrations

```bash
$ rails db:migrate
```

### 4. Include the module in your models

Add `RecycleBin::SoftDeletable` to any model you want to soft delete:

```ruby
class User < ApplicationRecord
  include RecycleBin::SoftDeletable
end

class Post < ApplicationRecord
  include RecycleBin::SoftDeletable
end

class Comment < ApplicationRecord
  include RecycleBin::SoftDeletable
end
```

### 5. Visit the web interface

Navigate to `/recycle_bin` in your Rails application to see the web interface!

## Usage 💡

### Basic Operations

Once you've included the `RecycleBin::SoftDeletable` module in your models:

```ruby
# Create a record
user = User.create(name: "John Doe", email: "john@example.com")

# Soft delete (goes to trash)
user.destroy
# or
user.soft_delete

# Check if deleted
user.deleted? # => true

# Restore from trash
user.restore

# Permanently delete (careful!)
user.destroy!
```

### Querying Records

The module provides several useful scopes:

```ruby
# Get all active (non-deleted) records (default scope)
User.all

# Get only deleted records
User.deleted

# Get all records including deleted ones
User.with_deleted

# Get only deleted records (alias)
User.only_deleted

# Get non-deleted records explicitly
User.not_deleted

# Restore a deleted record by ID
User.restore(123)
```

### Web Interface Features

The web interface (`/recycle_bin`) provides:

- **Dashboard Overview**: Statistics about deleted items
- **Item Listing**: View all deleted records with details
- **Filtering**: Filter by model type (User, Post, Comment, etc.)
- **Time Filters**: View items deleted today, this week, or this month
- **Individual Actions**: Restore or permanently delete single items
- **Bulk Actions**: Select multiple items to restore or delete
- **Item Details**: Click on any item to see full details and history

## Configuration ⚙️

Configure RecycleBin in `config/initializers/recycle_bin.rb`:

```ruby
RecycleBin.configure do |config|
  # Enable/disable web interface (default: true)
  config.enable_web_interface = true

  # Items per page in web interface (default: 25)
  config.items_per_page = 50

  # Auto-cleanup items after specified time (default: nil - disabled)
  config.auto_cleanup_after = 30.days

  # Method to get current user for audit trail (default: :current_user)
  config.current_user_method = :current_user

  # Authorization callback - restrict access to admins only
  config.authorize_with do |controller|
    # Example: Only allow admins
    controller.current_user&.admin?
  end
end
```

### Authorization

To restrict access to the web interface, use the `authorize_with` configuration:

```ruby
RecycleBin.configure do |config|
  config.authorize_with do |controller|
    # Only allow admins
    controller.current_user&.admin?
  end
end
```

If authorization fails, users will be redirected with an "Access denied" message.

## Auto-Cleanup 🗑️ (NEW in v1.3.0)

RecycleBin can automatically delete old trash items to keep your database clean.

### Quick Setup

**Step 1: Configure auto-cleanup**

```ruby
# config/initializers/recycle_bin.rb
RecycleBin.configure do |config|
  # Delete items older than 30 days
  config.auto_cleanup_after = 30.days

  # Optional: Configure batch size (default: 100)
  config.cleanup_batch_size = 100
end
```

**Step 2: Test it manually**

```bash
# Preview what will be deleted (safe - doesn't actually delete)
bundle exec rake recycle_bin:cleanup:dry_run

# Check current status
bundle exec rake recycle_bin:status

# Actually run cleanup
bundle exec rake recycle_bin:cleanup
```

**Step 3: Schedule it** (choose ONE method)

```ruby
# Option A: Whenever gem (most common)
# config/schedule.rb
every 1.day, at: '2:00 am' do
  rake 'recycle_bin:cleanup'
end

# Option B: Sidekiq-cron
# config/initializers/sidekiq.rb
Sidekiq::Cron::Job.create(
  name: 'RecycleBin cleanup',
  cron: '0 2 * * *',  # Daily at 2 AM
  class: 'RecycleBin::CleanupJob'
)

# Option C: System cron
# Add to crontab:
# 0 2 * * * cd /path/to/app && bundle exec rake recycle_bin:cleanup RAILS_ENV=production

# Option D: Heroku Scheduler
# Just add this command in Heroku dashboard:
# rake recycle_bin:cleanup
```

### Rake Tasks

RecycleBin provides several rake tasks for managing cleanup:

```bash
# Preview cleanup without deleting
rake recycle_bin:cleanup:dry_run

# Actually delete old items
rake recycle_bin:cleanup

# Delete items older than specific number of days
rake recycle_bin:cleanup DAYS=60

# Check cleanup status and pending deletions
rake recycle_bin:status

# View detailed statistics
rake recycle_bin:stats
```

### Scheduling Guide Generator

Generate a comprehensive scheduling guide for your infrastructure:

```bash
rails generate recycle_bin:schedule
```

This creates `doc/recycle_bin_scheduling.md` with:
- ✅ Personalized examples based on your setup
- ✅ 8+ scheduling methods (Whenever, Sidekiq-cron, GoodJob, Heroku, etc.)
- ✅ Platform-specific examples (AWS, Kubernetes, Docker)
- ✅ Troubleshooting guide
- ✅ Best practices

### Programmatic Usage

You can also run cleanup programmatically in your code:

```ruby
# Run cleanup with default configuration
result = RecycleBin.cleanup_old_items!

# Run with custom cutoff date
result = RecycleBin.cleanup_old_items!(cutoff_date: 60.days.ago)

# Dry run (preview only)
result = RecycleBin.cleanup_old_items!(dry_run: true)

# Check results
puts "Deleted: #{result[:deleted_count]} items"
puts "Success: #{result[:success]}"
result[:models_processed].each do |model, count|
  puts "  #{model}: #{count}"
end
```

### Background Job (Optional)

If you use a job processor (Sidekiq, GoodJob, DelayedJob, etc.), you can use the provided job:

```ruby
# Enqueue the cleanup job
RecycleBin::CleanupJob.perform_later

# With custom cutoff date
RecycleBin::CleanupJob.perform_later(cutoff_date: 60.days.ago)

# The job will:
# - Automatically retry on failures (up to 3 attempts)
# - Log all operations to Rails.logger
# - Report detailed results
# - Work with any ActiveJob backend
```

**Note**: The `RecycleBin::CleanupJob` is automatically available in your Rails app once the gem is installed. It's loaded by the Rails Engine autoloading system.

### Monitoring Cleanup Status

Check cleanup configuration and pending items:

```ruby
# Get cleanup status
status = RecycleBin.cleanup_status

if status[:enabled]
  puts "Auto-cleanup: ENABLED"
  puts "Cutoff date: #{status[:cutoff_date]}"
  puts "Items pending: #{status[:items_pending_deletion]}"
else
  puts "Auto-cleanup: DISABLED"
end

# Count items that will be deleted
count = RecycleBin.items_pending_cleanup
puts "#{count} items will be deleted on next cleanup"

# Count for specific date
count = RecycleBin.items_pending_cleanup(60.days.ago)
puts "#{count} items older than 60 days"
```

### Safety Features

RecycleBin cleanup includes multiple safety mechanisms:

**1. Dry-Run Mode**
```bash
# Preview without deleting
rake recycle_bin:cleanup:dry_run
```

**2. Confirmation Prompts**
```bash
$ rake recycle_bin:cleanup
Cutoff date: 2025-09-12 02:00:00
Items to be deleted: 42

⚠️  This will PERMANENTLY delete items. Continue? (y/N):
```

**3. Comprehensive Logging**
- All operations are logged
- Errors are tracked and reported
- Progress tracking for large datasets

**4. Batch Processing**
- Processes items in batches (default: 100)
- Prevents memory issues with large datasets
- Configurable batch size

**5. Error Recovery**
- Individual item failures don't stop the process
- Continues with other items
- Reports all errors at the end

### Example Output

```bash
$ rake recycle_bin:cleanup:dry_run

============================================================
        RecycleBin Cleanup (DRY RUN)
============================================================

Cutoff date: 2025-09-12 02:00:00
Items to be deleted: 42

🔍 DRY RUN MODE - No items will be deleted

============================================================
✅ Cleanup preview complete!
Total items would be deleted: 42

Breakdown by model:
  User: 10
  Post: 25
  Comment: 7
============================================================
```

### Best Practices

✅ **Do:**
- Start with a longer cleanup period (60+ days)
- Test with dry-run first
- Run during low-traffic hours (2-4 AM)
- Monitor logs for errors
- Set up alerts for failures

❌ **Don't:**
- Set cleanup period too short (<7 days)
- Skip dry-run testing
- Run during peak hours
- Ignore cleanup errors

### Troubleshooting

**No items being deleted?**

```ruby
# Check configuration
RecycleBin.config.auto_cleanup_after  # Should return a duration

# Check cutoff date
RecycleBin.calculate_cleanup_cutoff_date  # Should return a date

# Check for eligible items
RecycleBin.items_pending_cleanup  # Should return a count
```

**Cleanup not running on schedule?**

```bash
# Verify task exists
rake -T recycle_bin

# Test manually
rake recycle_bin:cleanup:dry_run

# Check scheduler logs
# - For cron: grep CRON /var/log/syslog
# - For Sidekiq: tail -f log/sidekiq.log
```

## Advanced Usage 🔧

### Custom Title Display

By default, RecycleBin tries to use `title`, `name`, or `email` fields for display. You can customize this:

```ruby
class User < ApplicationRecord
  include RecycleBin::SoftDeletable

  def recyclable_title
    "#{first_name} #{last_name} (#{email})"
  end
end
```

### Associations and Dependencies

RecycleBin works with Rails associations. The web interface will show related items:

```ruby
class User < ApplicationRecord
  include RecycleBin::SoftDeletable
  has_many :posts, dependent: :destroy
end

class Post < ApplicationRecord
  include RecycleBin::SoftDeletable
  belongs_to :user
  has_many :comments, dependent: :destroy
end
```

### Statistics and Reporting

Get statistics about your deleted items:

```ruby
# Get overall statistics
RecycleBin.stats
# => { deleted_items: 45, models_with_soft_delete: ["User", "Post", "Comment"] }

# Count deleted items across all models
RecycleBin.count_deleted_items # => 45

# Get models that have soft delete enabled
RecycleBin.models_with_soft_delete # => ["User", "Post", "Comment"]
```

## API Reference 📚

### Instance Methods

- `soft_delete` - Mark record as deleted
- `restore` - Restore deleted record
- `deleted?` - Check if record is deleted
- `destroy` - Soft delete (overrides Rails default)
- `destroy!` - Permanently delete from database
- `recyclable_title` - Display title for web interface

### Class Methods

- `.deleted` - Scope for deleted records only
- `.not_deleted` - Scope for active records only
- `.with_deleted` - Scope for all records including deleted
- `.only_deleted` - Alias for `.deleted`
- `.restore(id)` - Restore a record by ID
- `.deleted_records` - Get all deleted records

### Configuration Options

**Basic Settings:**
- `enable_web_interface` - Enable/disable web UI (default: true)
- `items_per_page` - Pagination limit (default: 25)
- `current_user_method` - Method to get current user (default: :current_user)
- `authorize_with` - Authorization callback block

**Auto-Cleanup Settings (v1.3.0):**
- `auto_cleanup_after` - Delete items older than this duration (default: nil - disabled)
- `cleanup_batch_size` - Number of items to process per batch (default: 100)

**Search & Export Settings:**
- `enable_full_text_search` - Enable full-text search (default: true)
- `searchable_fields` - Fields to search (default: title, name, email, etc.)
- `enable_csv_export` - Enable CSV export (default: true)
- `enable_json_export` - Enable JSON export (default: true)

## Generators 🛠️

### Install Generator

```bash
$ rails generate recycle_bin:install
```

Sets up RecycleBin in your Rails application. Creates:
- Configuration file at `config/initializers/recycle_bin.rb`
- Adds mount point to routes
- Displays setup instructions

### Add DeletedAt Generator

```bash
$ rails generate recycle_bin:add_deleted_at ModelName
```

Adds the `deleted_at` column to the specified model. Example:

```bash
$ rails generate recycle_bin:add_deleted_at User
$ rails generate recycle_bin:add_deleted_at Post
$ rails db:migrate
```

## Web Interface Routes 🛣️

The gem adds these routes to your application:

```
GET    /recycle_bin              # Dashboard/index
GET    /recycle_bin/trash        # List all deleted items
GET    /recycle_bin/trash/:model_type/:id # Show specific item
PATCH  /recycle_bin/trash/:model_type/:id/restore # Restore item
DELETE /recycle_bin/trash/:model_type/:id # Permanently delete
PATCH  /recycle_bin/trash/bulk_restore    # Bulk restore
DELETE /recycle_bin/trash/bulk_destroy    # Bulk delete
```

## Requirements 📋

- **Ruby**: >= 2.7.0
- **Rails**: >= 6.0
- **Database**: Any database supported by Rails (PostgreSQL, MySQL, SQLite, etc.)

## Examples 💼

### E-commerce Store

```ruby
class Product < ApplicationRecord
  include RecycleBin::SoftDeletable

  def recyclable_title
    "#{name} - #{sku}"
  end
end

# Soft delete a product
product = Product.find(1)
product.destroy # Goes to trash, can be restored

# View deleted products in admin panel at /recycle_bin
```

### Blog System

```ruby
class Post < ApplicationRecord
  include RecycleBin::SoftDeletable
  belongs_to :author, class_name: 'User'

  def recyclable_title
    title.truncate(50)
  end
end

class Comment < ApplicationRecord
  include RecycleBin::SoftDeletable
  belongs_to :post
  belongs_to :user

  def recyclable_title
    "Comment by #{user.name}: #{body.truncate(30)}"
  end
end
```

### User Management

```ruby
class User < ApplicationRecord
  include RecycleBin::SoftDeletable

  def recyclable_title
    "#{name} (#{email})"
  end
end

# Admin can restore accidentally deleted users
User.deleted.each do |user|
  puts "Deleted user: #{user.recyclable_title}"
end
```

## Troubleshooting 🔍

### Common Issues

**1. "uninitialized constant RecycleBin" error**
- Make sure you've added the gem to your Gemfile and run `bundle install`
- Restart your Rails server

**2. Routes not working**
- Ensure you've run `rails generate recycle_bin:install`
- Check that `mount RecycleBin::Engine => '/recycle_bin'` is in your `config/routes.rb`

**3. Records not appearing in trash**
- Verify you've included `RecycleBin::SoftDeletable` in your model
- Ensure the `deleted_at` column exists (run the migration)
- Check that you're calling `.destroy` not `.delete`

**4. Web interface shows "Access denied"**
- Check your authorization configuration in the initializer
- Ensure the current user meets your authorization requirements

### Debugging

Enable debug logging to see what's happening:

```ruby
# In development.rb or console
Rails.logger.level = :debug
```

## Contributing 🤝

Bug reports and pull requests are welcome on GitHub at https://github.com/R95-del/recycle_bin.

## License 📄

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog 📝

## [1.2.0] - 2025-09-08

### Added
- **🎨 Enhanced Analytics Dashboard**: Complete redesign with comprehensive statistics and visual charts
- **🔍 Improved Search System**: Priority-based search with exact matching, starts-with matching, and intelligent filtering
- **🎛️ Advanced Filtering UI**: Modern card-based layout with collapsible advanced filters
- **📊 Dashboard vs All Items Pages**: Distinct pages with different purposes - overview vs detailed management
- **📈 Weekly Activity Charts**: Visual representation of deletion activity over the past 7 days
- **🥧 Model Breakdown Statistics**: Pie chart showing distribution of deleted items by model type
- **🏷️ Active Filters Display**: Shows currently applied filters with individual removal options
- **📱 Responsive Design**: Mobile-friendly interface with proper spacing and typography
- **⚡ Collection Method Enhancement**: Added `reject` method to `DeletedItemsCollection` for better compatibility

### Fixed
- **🎯 Search Precision**: Fixed search showing irrelevant results by implementing priority-based matching
- **🥇 Primary Field Priority**: Search now prioritizes title/name/subject fields over content fields
- **🚫 False Match Reduction**: Removed broad content field searches that caused incorrect results
- **👮‍♂️ RuboCop Compliance**: Fixed code style issues and improved code quality
- **🧪 Test Coverage**: Added comprehensive tests for new search functionality

### Changed
- **🔄 Search Algorithm**: Complete rewrite with 5-tier priority system (exact match → starts with → contains → ID → class name)
- **✨ UI/UX Improvements**: Modern gradient design, better spacing, and intuitive navigation
- **🏗️ Dashboard Architecture**: Separated dashboard overview from detailed item management
- **📂 Filter Organization**: Grouped filters logically with expandable sections
- **📏 Search Term Length**: Applied minimum length requirements for different search types
- **🏆 Code Quality**: Improved method organization and reduced complexity

### Performance
- **🚀 Search Optimization**: Reduced false matches and improved search relevance
- **⚡ UI Responsiveness**: Faster page loads with optimized CSS and layout
- **🧠 Memory Efficiency**: Better handling of large datasets in search results

## [1.1.1] - 2025-05-26

### Fixed
- Fixed critical bug in user authentication flow
- Resolved memory leak in background job processing
- Corrected deprecation warnings for Rails 7.1 compatibility
- Fixed race condition in concurrent database writes

### Changed
- Improved error handling in API responses
- Updated dependency versions for security patches
- Enhanced logging for better debugging experience

### Security
- Patched potential XSS vulnerability in form helpers
- Updated vulnerable dependencies to secure versions

## [1.1.0] - 2025-05-25

### Added
- **Proper pagination**: Navigate through all deleted records with page controls
- **Configurable page sizes**: Choose 25, 50, 100, or 250 items per page
- **Accurate item counting**: Shows real total counts instead of limited counts
- **Enhanced statistics**: Added today/week deletion counts
- **Better performance**: Optimized handling of large datasets
- **Per-page controls**: User-selectable items per page options
- **Memory optimization**: DeletedItemsCollection class for efficient data handling

### Fixed
- **Removed artificial limits**: No more 25/100 item display limits that prevented showing all records
- **Pagination persistence**: Filters maintained across page navigation
- **Memory usage**: Better handling of large datasets without loading all into memory
- **Count accuracy**: Total counts now reflect actual database records
- **Performance bottlenecks**: Eliminated inefficient loading of all records at once

### Changed
- **TrashController**: Complete rewrite with proper pagination logic
- **Index view**: Enhanced UI with comprehensive pagination controls and statistics
- **RecycleBin module**: Improved counting methods and performance optimizations
- **Statistics calculation**: More efficient counting without loading full record sets

### Performance
- **Large dataset support**: Now efficiently handles 5000+ deleted records
- **Lazy loading**: Only loads current page items, not all records
- **Optimized queries**: Better database query patterns for counting and filtering
- **Memory efficient**: Reduced memory footprint for large trash collections

### Technical Details
- Added `DeletedItemsCollection` class for efficient pagination
- Implemented proper offset/limit handling
- Enhanced filtering with maintained pagination state
- Improved error handling for large datasets

## [1.0.0] - 2025-05-24

### Added
- Initial release of RecycleBin gem
- Soft delete functionality for ActiveRecord models
- Web interface for managing trashed items
- Restore functionality for deleted records
- Bulk operations for multiple items
- JSON API support for programmatic access

### Contributors
- Rishi Somani
- Shobhit Jain
- Raghav Agrawal

---

**Made with ❤️ for the Rails community**

*Need help? Open an issue on [GitHub](https://github.com/R95-del/recycle_bin) or check out the web interface at `/recycle_bin` in your Rails app.*

## Advanced Features 🚀

### Enhanced Search & Discovery

RecycleBin now provides powerful search capabilities across all your deleted items:

```ruby
# Search across all fields including title, name, email, content, etc.
# Visit /recycle_bin?search=john@example.com

# Search results are highlighted in the interface
# Search works across all model types and attributes
```

**Search Features:**
- **Full-text Search**: Search across all item fields and attributes
- **Smart Highlighting**: Search terms are highlighted in results
- **Cross-model Search**: Find items across all soft-deleted models
- **Real-time Results**: Instant search with live filtering

### Advanced Filtering Options

Go beyond basic filtering with advanced options:

```ruby
# Filter by user who deleted the item
/recycle_bin?deleted_by=123

# Filter by item size
/recycle_bin?size=large  # small, medium, large

# Filter by date range
/recycle_bin?date_from=2024-01-01&date_to=2024-12-31

# Combine multiple filters
/recycle_bin?search=john&type=User&size=medium&time=month
```

**Filter Types:**
- **Model Type**: Filter by specific model (User, Post, Comment, etc.)
- **Time Periods**: Today, This Week, This Month, This Year
- **User Filtering**: Find items deleted by specific users
- **Size Classification**: Small (< 1KB), Medium (1KB-100KB), Large (> 100KB)
- **Date Ranges**: Custom from/to date filtering
- **Active Filter Display**: See all active filters with easy removal

### Export Functionality

Export your filtered results in multiple formats:

```ruby
# Export current results to CSV
/recycle_bin?format=csv&search=john&type=User

# Export current results to JSON
/recycle_bin?format=json&time=month

# Export includes all current filters and search terms
# Filenames include filter information and timestamps
```

**Export Features:**
- **CSV Export**: Structured data for spreadsheet applications
- **JSON Export**: Programmatic access to your data
- **Filter Preservation**: Exports respect all current filters
- **Smart Filenames**: Include search terms and filter info
- **Large Dataset Support**: Efficient export of thousands of items

### Improved Error Handling & Logging

Enhanced error tracking and debugging capabilities:

```ruby
RecycleBin.configure do |config|
  # Enable external error logging (e.g., Sentry)
  config.error_logging_service = ->(error_context) {
    Sentry.capture_exception(error_context[:error], extra: error_context)
  }

  # Configure search settings
  config.enable_full_text_search = true
  config.searchable_fields = %w[title name email content body description]
  config.max_search_length = 100

  # Configure export settings
  config.enable_csv_export = true
  config.enable_json_export = true
  config.max_export_items = 10000
end
```

**Logging Features:**
- **Structured Logging**: JSON-formatted error logs with context
- **External Integration**: Support for Sentry, LogRocket, etc.
- **Debug Information**: Comprehensive debugging data
- **Performance Tracking**: Monitor search and export performance
- **User Context**: Track which users perform which actions

### Configuration Options

```ruby
# config/initializers/recycle_bin.rb
RecycleBin.configure do |config|
  # Search configuration
  config.enable_full_text_search = true
  config.searchable_fields = %w[title name email content body description]
  config.max_search_length = 100
  config.search_timeout = 30.seconds
  config.enable_fuzzy_search = false
  config.min_search_length = 2

  # Export configuration
  config.enable_csv_export = true
  config.enable_json_export = true
  config.max_export_items = 10000
  config.export_timeout = 5.minutes
  config.include_metadata = true
  config.compress_large_exports = true

  # Advanced features
  config.enable_advanced_filters = true
  config.enable_search_highlighting = true
  config.max_search_results = 10000
  config.enable_audit_logging = false
end
```
