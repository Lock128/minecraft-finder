# Utilities

## PreferencesService

The `PreferencesService` class handles persistent storage of all search parameters using SharedPreferences.

### Features

- **Complete Search Persistence**: Automatically saves and restores all search parameters
- **World Seed Storage**: Saves the last entered world seed
- **Coordinate Memory**: Remembers X, Y, Z coordinates between sessions
- **Search Radius Persistence**: Saves preferred search radius
- **Default Fallbacks**: Returns sensible defaults if no values have been saved
- **Empty Value Protection**: Prevents saving empty values to maintain data integrity

### Usage

```dart
// Load individual parameters
String lastSeed = await PreferencesService.getLastSeed();
String lastX = await PreferencesService.getLastX();
String lastY = await PreferencesService.getLastY();
String lastZ = await PreferencesService.getLastZ();
String lastRadius = await PreferencesService.getLastRadius();

// Save individual parameters
await PreferencesService.saveLastSeed('123456789');
await PreferencesService.saveLastX('100');
await PreferencesService.saveLastY('64');
await PreferencesService.saveLastZ('-200');
await PreferencesService.saveLastRadius('75');

// Load all parameters at once
Map<String, String> params = await PreferencesService.getAllSearchParams();
```

### Default Values

- **Seed**: `8674308105921866736`
- **X Coordinate**: `0`
- **Y Coordinate**: `-59`
- **Z Coordinate**: `0`
- **Search Radius**: `50`

### Implementation Details

- Uses SharedPreferences for cross-platform persistent storage
- Individual storage keys for each parameter type
- Batch loading capability for efficient initialization
- Automatically handles initialization and error cases