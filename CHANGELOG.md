# Changelog

## [1.3.0] - 2025-10-12

### Added
- **Auto-Cleanup System**: Automated deletion of old soft-deleted records based on age
- **Cleanup Service**: Core `CleanupService` class with batch processing and safety features
- **Rake Tasks**: Four new rake tasks for manual cleanup operations
  - `rake recycle_bin:cleanup` - Permanently delete old items with confirmation
  - `rake recycle_bin:cleanup:dry_run` - Preview cleanup without deleting
  - `rake recycle_bin:status` - Check auto-cleanup configuration status
  - `rake recycle_bin:stats` - View detailed statistics with cleanup info
- **Background Job Support**: Optional `CleanupJob` for scheduled execution via ActiveJob
- **Configuration Options**: Two new configuration options
  - `config.auto_cleanup_after` - Set age threshold for automatic cleanup
  - `config.cleanup_batch_size` - Control batch size for cleanup operations (default: 100)
- **Module-Level Methods**: New public API methods for programmatic access
  - `RecycleBin.cleanup_old_items!` - Execute cleanup with options
  - `RecycleBin.cleanup_status` - Get current cleanup configuration status
  - `RecycleBin.items_pending_cleanup` - Count items eligible for cleanup

### Features
- **Safety First Design**: Multiple safety mechanisms to prevent accidental data loss
  - Dry-run mode for previewing deletions
  - Manual confirmation prompts in rake tasks
  - Batch processing to prevent memory issues
  - Comprehensive error handling and logging
  - Configuration validation
- **Flexible Scheduling**: Works with any scheduling system
  - Whenever gem integration examples
  - Sidekiq-cron integration examples
  - System cron examples
  - Heroku Scheduler examples
  - Manual rake task execution
- **Comprehensive Monitoring**: Track and monitor cleanup operations
  - Detailed result reporting
  - Per-model deletion counts
  - Error tracking and logging
  - Status checking APIs

### Fixed
- **Rails Detection**: Improved Rails availability checking in stats method
- **Configuration Validation**: Fixed `errors` method to return array of error messages instead of boolean

### Changed
- **Documentation**: Extensive README updates with ~275 lines of auto-cleanup documentation
  - Quick setup guide (3 steps)
  - Complete rake tasks reference
  - Programmatic usage examples
  - Background job integration guide
  - Monitoring and status checking
  - Safety features explanation
  - Best practices and troubleshooting
- **Configuration Organization**: Reorganized config options into logical categories

### Testing
- **Comprehensive Test Coverage**: Added 30+ new tests
  - CleanupService specs (16 examples)
  - CleanupJob specs (8 examples)
  - Module-level method specs (14 examples)
  - Integration tests for rake tasks
- **Test Suite Status**: 135 examples, 0 failures (100% pass rate)

### Documentation
- **README.md**: Added ~275 lines of comprehensive auto-cleanup documentation
- **CHANGELOG.md**: Complete v1.3.0 release notes

### Performance
- **Batch Processing**: Processes items in configurable batches to prevent memory issues
- **Efficient Querying**: Uses `find_each` for memory-efficient iteration
- **Optimized Deletion**: Bulk deletion within batches for better performance

### Technical Details
- Added `RecycleBin::CleanupService` in `app/services/recycle_bin/`
- Added `RecycleBin::CleanupJob` in `app/jobs/recycle_bin/`
- Added comprehensive rake tasks in `lib/tasks/recycle_bin_tasks.rake`
- Enhanced `RecycleBin` module with cleanup methods
- Updated `Configuration` class with new options and validation
- Added ENV variable support for skipping engine loading in tests

### Breaking Changes
None - All changes are backward compatible

### Upgrade Notes
- The new auto-cleanup feature is **opt-in** and disabled by default
- No database migrations required
- No code changes required for existing functionality
- To enable, simply set `config.auto_cleanup_after` in your initializer

## [1.2.0] - 2025-09-08

### Added
- **Enhanced Analytics Dashboard**: Complete redesign with comprehensive statistics and visual charts
- **Improved Search System**: Priority-based search with exact matching, starts-with matching, and intelligent filtering
- **Advanced Filtering UI**: Modern card-based layout with collapsible advanced filters
- **Dashboard vs All Items Pages**: Distinct pages with different purposes - overview vs detailed management
- **Weekly Activity Charts**: Visual representation of deletion activity over the past 7 days
- **Model Breakdown Statistics**: Pie chart showing distribution of deleted items by model type
- **Active Filters Display**: Shows currently applied filters with individual removal options
- **Responsive Design**: Mobile-friendly interface with proper spacing and typography
- **Collection Method Enhancement**: Added `reject` method to `DeletedItemsCollection` for better compatibility

### Fixed
- **Search Precision**: Fixed search showing irrelevant results by implementing priority-based matching
- **Primary Field Priority**: Search now prioritizes title/name/subject fields over content fields
- **False Match Reduction**: Removed broad content field searches that caused incorrect results
- **RuboCop Compliance**: Fixed code style issues and improved code quality
- **Test Coverage**: Added comprehensive tests for new search functionality

### Changed
- **Search Algorithm**: Complete rewrite with 5-tier priority system (exact match → starts with → contains → ID → class name)
- **UI/UX Improvements**: Modern gradient design, better spacing, and intuitive navigation
- **Dashboard Architecture**: Separated dashboard overview from detailed item management
- **Filter Organization**: Grouped filters logically with expandable sections
- **Search Term Length**: Applied minimum length requirements for different search types
- **Code Quality**: Improved method organization and reduced complexity

### Performance
- **Search Optimization**: Reduced false matches and improved search relevance
- **UI Responsiveness**: Faster page loads with optimized CSS and layout
- **Memory Efficiency**: Better handling of large datasets in search results

### Technical Details
- Enhanced `filter_by_search` method with priority-based matching logic
- Added comprehensive dashboard data calculation methods
- Implemented collapsible filter sections with JavaScript
- Updated navigation highlighting for active pages
- Added `reject` method to both controller and spec `DeletedItemsCollection` classes

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
- Raghav Agrawal  
- Shobhit Jain