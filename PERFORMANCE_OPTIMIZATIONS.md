# Performance Optimizations

This document outlines the performance optimizations implemented for handling large datasets in the Ascend app.

## Overview

The app has been optimized to handle large datasets efficiently through:
- Intelligent caching strategies
- Background processing for heavy calculations
- Indexed data structures for faster lookups
- Lazy loading where appropriate

## Optimizations Implemented

### 1. WorkoutHistoryManager

#### Date Indexing
- **Problem**: Filtering workouts by date range required scanning all workouts (O(n))
- **Solution**: Index workouts by date with sorted date array for binary search
- **Performance**: O(log n) lookup time instead of O(n)
- **Implementation**:
  - `workoutsByDate: [Date: [Workout]]` - Index workouts by day
  - `sortedWorkoutDates: [Date]` - Sorted dates for binary search
  - Indexes rebuilt automatically when workouts change

#### Volume Calculation Caching
- **Problem**: `getAllTimeVolume()` recalculated from all workouts every time
- **Solution**: Cache result with timestamp-based invalidation
- **Performance**: O(1) for cached lookups, O(n) only when cache invalid
- **Cache Duration**: 60 seconds (configurable via `cacheValidityDuration`)

#### Background Processing
- **Problem**: Large volume calculations blocked main thread
- **Solution**: Process on background queue for datasets > 50 workouts
- **Performance**: Non-blocking UI, calculations happen asynchronously
- **Implementation**: Uses dedicated `processingQueue` with `.utility` QoS

#### Smart Volume Calculation
- Small datasets (< 50 workouts): Synchronous calculation
- Large datasets (≥ 50 workouts): Asynchronous calculation with cached fallback
- Date range queries use indexed lookup instead of full scan

### 2. ProgressViewModel

#### Streak Calculation Caching
- **Problem**: `calculateStreaks()` sorted dates every call (O(n log n))
- **Solution**: Cache sorted dates and streak results
- **Performance**: 
  - First call: O(n log n) for sorting
  - Subsequent calls: O(n) using cached sorted dates
  - Cached results: O(1) for 60 seconds
- **Cache Invalidation**: Automatically invalidated when workout dates or rest days change

#### Background Streak Processing
- **Problem**: Streak calculation for large datasets (> 100 dates) blocked UI
- **Solution**: Process on background queue for large datasets
- **Performance**: Non-blocking UI, results update when ready

#### Volume Data Caching
- **Problem**: Weekly volume data recalculated every access
- **Solution**: Cache calculated data with timestamp
- **Cache Duration**: 5 minutes (configurable via `volumeCacheValidity`)
- **Background Processing**: Large datasets calculated asynchronously

#### Smart Volume Updates
- Small datasets (< 100 workouts): Synchronous update
- Large datasets (≥ 100 workouts): Asynchronous update on background queue

### 3. TemplatesViewModel

#### Background Loading
- **Problem**: Template loading and decoding blocked main thread
- **Solution**: Load and decode on background queue
- **Performance**: Non-blocking app startup

#### Calisthenics Template Caching
- **Problem**: Calisthenics templates regenerated every load
- **Solution**: Cache generated templates
- **Performance**: O(1) lookup instead of O(n) generation

#### Background Saving
- **Problem**: Template saving blocked main thread
- **Solution**: Save on background queue
- **Performance**: Non-blocking UI updates

### 4. General Optimizations

#### Debounced Saves
- **Problem**: Multiple rapid saves caused excessive UserDefaults writes
- **Solution**: Debounce saves with 0.5 second delay
- **Performance**: Reduces I/O operations by batching writes
- **Implementation**: `PerformanceOptimizer.debouncedSave()`

#### Dedicated Processing Queues
- Each ViewModel uses dedicated background queue
- Proper QoS levels (`.userInitiated`, `.utility`)
- Prevents queue contention

#### Cache Invalidation Strategy
- Automatic invalidation when source data changes
- Timestamp-based expiration
- Manual invalidation for critical updates

## Performance Metrics

### Before Optimizations
- **Workout filtering**: O(n) - scanned all workouts
- **Volume calculation**: O(n) - recalculated every time
- **Streak calculation**: O(n log n) - sorted every time
- **Template loading**: Blocked main thread

### After Optimizations
- **Workout filtering**: O(log n) - binary search on indexed dates
- **Volume calculation**: O(1) cached, O(n) only when invalid
- **Streak calculation**: O(1) cached, O(n) with cached sort
- **Template loading**: Non-blocking background processing

## Scalability

The optimizations ensure the app performs well with:
- **Small datasets** (< 50 items): Instant synchronous processing
- **Medium datasets** (50-500 items): Cached results with background updates
- **Large datasets** (> 500 items): Fully asynchronous with progressive loading

## Memory Management

- Caches are automatically invalidated to prevent memory bloat
- Weak references used in async closures
- Background queues properly managed
- No retain cycles introduced

## Future Optimizations

Potential areas for further optimization:
1. **Pagination**: Load workouts in batches for very large datasets
2. **Lazy Loading**: Load templates/exercises on-demand
3. **Core Data**: Migrate from UserDefaults to Core Data for better performance
4. **Image Caching**: Cache exercise images/videos if added
5. **Predictive Caching**: Pre-calculate likely-needed data

## Testing

Performance optimizations have been tested with:
- Small datasets (< 50 workouts)
- Medium datasets (50-500 workouts)
- Large datasets (> 500 workouts)

All optimizations maintain data integrity and UI responsiveness.
