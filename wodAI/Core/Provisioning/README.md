# WodAI User Provisioning Workflow

## Overview

The provisioning workflow is a multi-step onboarding process for new users that collects essential fitness information to personalize their workout experience. This workflow is triggered automatically after a user signs up and authenticates for the first time.

## Features

### 1. **Progressive Multi-Step Form**
- Visual progress bar showing completion status
- Smooth transitions between steps
- Back navigation support
- Validation before proceeding to next step

### 2. **Data Collection Steps**

#### Step 1: Gender Selection
- Male, Female, Other, or Prefer not to say options
- Clean card-based UI with icons

#### Step 2: Fitness Level
- Four levels: Beginner, Intermediate, Advanced, Elite
- Each level includes a descriptive subtitle
- Visual icons to represent each level

#### Step 3: Workout Duration
- Pre-defined duration options: 30, 45, 60, or 90 minutes
- Helps calibrate workout volume

#### Step 4: Performance Benchmarks
- Multiple benchmark options:
  - Back Squat (lbs)
  - Deadlift (lbs)
  - Bench Press (lbs)
  - Overhead Press (lbs)
  - Pull-ups (reps)
  - 1 Mile Run (time format MM:SS)
- Users must select at least one benchmark
- Smart input fields with appropriate keyboards
- Time input field for running with auto-formatting

#### Step 5: Injuries & Limitations
- Optional step - users can skip if no injuries
- Pre-defined body parts list
- Severity levels: Minor, Moderate, Severe
- Optional description field for additional context
- Visual indicators for injury severity

### 3. **UI/UX Design**
- Consistent with WodAI design system
- Uses ThemeColors from Assets
- Smooth animations and transitions
- Responsive to different screen sizes
- Accessibility-friendly with clear labels

### 4. **State Management**
- Integrated with AuthManager
- Automatic provisioning check on login
- Persistent storage using UserDefaults
- Clean state transitions

## Implementation Details

### File Structure
```
wodAI/Core/Provisioning/
├── ProvisioningModels.swift      # Data models and enums
├── ProvisioningViewModel.swift    # Business logic and state management
├── ProvisioningView.swift        # Main container view
├── BenchmarksInputView.swift     # Benchmark selection and input
└── InjuriesInputView.swift       # Injury management
```

### Key Components

1. **ProvisioningModels.swift**
   - Defines all enums (Gender, FitnessLevel, etc.)
   - Data structures for storing user selections
   - API request/response models (stubs)

2. **ProvisioningViewModel.swift**
   - Manages form state across all steps
   - Handles validation logic
   - Submits data to backend (currently stubbed)

3. **ProvisioningView.swift**
   - Main container with progress bar
   - Navigation between steps
   - Individual step views for gender, fitness level, and duration

4. **BenchmarksInputView.swift**
   - Dynamic benchmark selection
   - Smart input fields with validation
   - Time input for running benchmarks

5. **InjuriesInputView.swift**
   - Injury list management
   - Add/remove injuries
   - Detailed injury input sheet

### Integration Points

1. **AuthManager Updates**
   - Added `isProvisioned` and `needsProvisioning` properties
   - `checkProvisioningStatus()` method
   - `completeProvisioning()` method

2. **ContentView Updates**
   - Checks provisioning status after authentication
   - Shows ProvisioningView when needed
   - Seamless transition to main app after completion

3. **API Integration (Stubbed)**
   - `ProvisioningService.checkProvisioningStatus()`
   - `ProvisioningService.provisionUser()`
   - Ready for backend implementation

## API Integration Guide

When the backend is ready, update these methods in `ProvisioningViewModel.swift`:

1. **Check Provisioning Status**
```swift
// Replace the stub in ProvisioningService.checkProvisioningStatus
// with actual GraphQL query
```

2. **Submit Provisioning Data**
```swift
// Replace the stub in submitProvisioning()
// with actual GraphQL mutation
```

The request model (`ProvisionUserRequest`) is already structured to match the expected API format.

## Testing

To test the provisioning flow:

1. Clear app data or use a new simulator
2. Sign up with a new account
3. The provisioning flow should appear automatically
4. Complete all steps and verify data is collected
5. After completion, the main app should load
6. Subsequent logins should bypass provisioning

To force re-provisioning (for testing):
```swift
UserDefaults.standard.set(false, forKey: "userProvisioned")
```

## Design Considerations

- **Accessibility**: All interactive elements have proper labels
- **Error Handling**: Graceful fallbacks for API failures
- **Performance**: Lightweight views with minimal memory footprint
- **Flexibility**: Easy to add/remove questions or modify flow

## Future Enhancements

1. Add more benchmark options
2. Include equipment availability questions
3. Add fitness goals selection
4. Implement progress photos upload
5. Add workout preference questions (strength vs cardio bias)
