# Recording Services Consolidation Plan

## Current Services Analysis

### Controllers (7 files):
1. **RecordingAuthManager** - Authentication & Google Drive integration
2. **RecordingStateManager** - Recording state & timers
3. **RecordingDriveSyncManager** - Drive synchronization
4. **RecordingFileManager** - File operations
5. **RecordingOperationsManager** - Recording operations
6. **RecordingPlaybackManager** - Playback functionality
7. **RecordingPublishingManager** - Publishing/sharing

### Services (9 files):
1. **AudioService** - Core audio functionality
2. **UserRecordingService** - User recording management
3. **PublicRecordingService** - Public recordings
4. **DeletedRecordingService** - Deleted recordings
5. **LocalAudioService** - Local audio operations
6. **AudioCacheService** - Audio caching
7. **AudioForegroundService** - Background audio
8. **BackgroundService** - Background operations
9. **AudioFileMapping** - File mapping

## Consolidation Strategy

### Phase 1: Merge Related Controllers
- **RecordingStateManager** + **RecordingOperationsManager** → **UnifiedRecordingManager**
- **RecordingFileManager** + **RecordingPlaybackManager** → **RecordingMediaManager**
- Keep **RecordingAuthManager** separate (authentication is distinct)
- Keep **RecordingDriveSyncManager** separate (Drive integration is complex)
- Keep **RecordingPublishingManager** separate (publishing workflow)

### Phase 2: Consolidate Services
- **UserRecordingService** + **PublicRecordingService** + **DeletedRecordingService** → **UnifiedRecordingDataService**
- **AudioService** + **LocalAudioService** + **AudioForegroundService** → **CoreAudioService**
- Keep **AudioCacheService** (caching is specialized)
- Keep **BackgroundService** (background operations)
- Keep **AudioFileMapping** (file mapping utility)

### Phase 3: Create Unified Interface
```dart
class UnifiedRecordingService {
  final UnifiedRecordingManager _recordingManager;
  final RecordingMediaManager _mediaManager;
  final UnifiedRecordingDataService _dataService;
  final CoreAudioService _audioService;
  
  // Single interface for all recording operations
}
```

## Benefits
- Reduced complexity: 16 services → 6 services
- Better maintainability
- Reduced memory footprint
- Cleaner API surface
- Easier testing

## Implementation Priority
1. **High**: Merge state and operations managers
2. **Medium**: Consolidate recording data services
3. **Low**: Full unification (requires extensive testing)

## Files to Modify
- lib/controller/recording/*.dart
- lib/services/audio/*.dart
- lib/controller/recording_controller.dart
- All screens using recording functionality