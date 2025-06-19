# GymProfile Equipment Database Integration

## Overview
This implementation updates the GymProfile feature to read equipment from the database using the Equipment GraphQL query. The solution provides a seamless integration while maintaining backward compatibility with existing local equipment options.

## Key Components Added/Modified

### 1. Equipment Model (`Equipment.swift`)
- New model to represent equipment fetched from the database
- Maps database equipment names to local `EquipmentOption` enum values
- Provides conversion from GraphQL Equipment type

### 2. EquipmentManager (`EquipmentManager.swift`)
- Singleton manager for fetching and caching equipment data
- Implements 24-hour cache to reduce server load
- Provides methods to:
  - Fetch equipment from database
  - Get available equipment options
  - Map between database IDs and local enums
  - Handle offline scenarios with cache

### 3. Updated AddEditGymProfileView
- Integrated EquipmentManager to fetch equipment from database
- Added loading states for equipment fetching
- Implemented error handling with fallback to local equipment options
- Added refresh button to manually update equipment list
- Gracefully handles offline mode using cached or default equipment

### 4. Updated GraphQL Queries/Mutations
- `GymProfile.graphql`: Added equipment field with id and name
- `UpdateGymProfile.graphql`: Added equipment field to response

## Implementation Details

### Equipment Mapping
The system maps database equipment names to local EquipmentOption enums:
```swift
"Bodyweight" -> .bodyweight
"Dumbbells" -> .dumbbells
"Barbell" -> .barbell
// ... etc
```

### Error Handling
- Network errors display a warning but allow users to continue with default equipment
- Cached equipment is used when available
- Fallback to all equipment options if database fetch fails

### UI/UX Considerations
1. **Loading State**: Shows spinner while fetching equipment for first time
2. **Error State**: Displays subtle warning if equipment fetch fails
3. **Refresh Option**: Manual refresh button to update equipment list
4. **Seamless Fallback**: Users can always select equipment even if database is unavailable

## Usage Flow

1. When user opens AddEditGymProfileView:
   - EquipmentManager fetches equipment from database (if not cached)
   - Loading spinner shown if first fetch
   - Equipment options populated from database response

2. Equipment Selection:
   - Users see only equipment available in database
   - If fetch fails, all default equipment options are shown
   - Selected equipment stored as EquipmentOption enum values

3. Workout Generation:
   - Selected equipment from gym profile used in workout generation
   - Equipment passed to backend as string values from enum

## Benefits

1. **Dynamic Equipment**: Equipment list can be updated server-side without app updates
2. **Consistency**: All users see the same equipment options
3. **Offline Support**: Cached equipment allows offline usage
4. **Backward Compatible**: Existing gym profiles continue to work
5. **Error Resilient**: App functions even if equipment fetch fails

## Next Steps

1. Run `./apollo-ios-cli generate` to regenerate GraphQL types
2. Test equipment fetching with various network conditions
3. Verify equipment mapping matches backend values
4. Consider adding equipment icons/images from database

## Important Notes

- Equipment names in database must match the mapping in Equipment.swift
- Cache duration is set to 24 hours but can be adjusted
- Manual refresh available for immediate updates
- All existing gym profiles will continue to work with their saved equipment
