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

## Features ✨

- **Soft Delete**: Records are marked as deleted instead of being permanently removed
- **Web Interface**: Beautiful, responsive dashboard to view and manage deleted items
- **Easy Integration**: Simple module inclusion in your models
- **Bulk Operations**: Restore or permanently delete multiple items at once
- **Model Filtering**: Filter deleted items by model type and time
- **Rails Generators**: Automated setup with generators
- **Configurable**: Flexible configuration options
- **Statistics Dashboard**: Overview of your deleted items

## Installation 📦

Add this line to your application's Gemfile:

```ruby
gem 'recycle_bin', '~> 1.1'
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

- `enable_web_interface` - Enable/disable web UI (default: true)
- `items_per_page` - Pagination limit (default: 25)
- `auto_cleanup_after` - Auto-delete after time period (default: nil)
- `current_user_method` - Method to get current user (default: :current_user)
- `authorize_with` - Authorization callback block

## Generators 🛠️

### Install Generator

```bash
$ rails generate recycle_bin:install
```

Sets up RecycleBin in your Rails application.

### Add DeletedAt Generator

```bash
$ rails generate recycle_bin:add_deleted_at ModelName
```

Adds the `deleted_at` column to the specified model.

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
