# Changelog

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