# Changelog

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