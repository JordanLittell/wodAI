# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

wodAI is an iOS fitness application built with SwiftUI that generates AI-powered workouts. The app uses a GraphQL API backend and follows MVVM architecture with reactive programming patterns.

## Development Commands

### Building and Running
- **Build**: Use Xcode to build the project (`Cmd+B`)
- **Run**: Use Xcode to run on simulator or device (`Cmd+R`)
- **Test**: Use Xcode Test Navigator or `Cmd+U`

### GraphQL Code Generation
```bash
# Generate GraphQL schema and operations (run from project root)
apollo-ios-cli generate --config apollo-codegen-config.json
```

### Configuration Management
- Build configurations are managed via `.xcconfig` files in `/Configurations/`
- Debug builds use `http://localhost:3000/graphql`
- Release builds use `https://move-adapt.com/graphql`

## Architecture Overview

### Core Structure
- **wodAI/**: Main iOS application
- **wodAiAPI/**: Swift Package containing generated GraphQL types
- **Configurations/**: Build configuration files (.xcconfig)

### Key Architectural Patterns

**MVVM + ObservableObject**
- ViewModels use `@Published` properties for reactive UI updates
- Views use `@StateObject` and `@ObservedObject` for state binding
- Centralized managers (AuthManager, WODSessionManager, etc.) for shared state

**GraphQL Integration**
- Apollo iOS client with custom authorization interceptor
- Generated type-safe operations in wodAiAPI package
- Automatic token injection and session management

**Authentication Flow**
- JWT-based authentication with automatic token refresh
- Google Sign-In integration
- Session expiration handling with NotificationCenter events

### Core Components

**Authentication**
- `AuthManager`: Centralized auth state and token management
- `ContentView`: Root view with auth state routing
- Automatic logout on GraphQL unauthorized errors

**Workout System**
- `EnhancedWorkoutGeneratorViewModel`: Multi-step workout creation flow
- `WODSessionManager`: Active workout session tracking
- `GymProfileManager`: Equipment-based workout customization

**Data Layer**
- `EquipmentManager`: Equipment database with 24-hour caching
- GraphQL queries with automatic error handling
- Local state management for offline scenarios

### Environment Configuration

The app uses a multi-environment setup:

```swift
// AppConfig.swift handles endpoint switching
#if DEBUG
    "http://localhost:3000/graphql"  // Development
#else
    "https://move-adapt.com/graphql"  // Production
#endif
```

### Dependencies

**External Packages**
- Apollo iOS (1.20.0): GraphQL client
- Google Sign-In: Authentication
- SwiftUI/Combine: UI and reactive programming

**Internal Packages**
- wodAiAPI: Generated GraphQL types and operations

## Key Development Notes

### GraphQL Schema Updates
When backend schema changes, regenerate code:
1. Update schema: `apollo-ios-cli fetch-schema --config apollo-codegen-config.json`
2. Generate code: `apollo-ios-cli generate --config apollo-codegen-config.json`

### Authentication Integration
All GraphQL requests automatically include authentication headers via the Apollo interceptor chain. Session expiration triggers automatic logout.

### Equipment System
Equipment data is fetched from the database with 24-hour caching. The `EquipmentManager` handles offline scenarios gracefully.

### Build Configuration
- Use Debug configuration for local development
- Release configuration points to production API
- xcconfig files manage environment-specific settings

### State Management Patterns
- Use `@StateObject` for view model ownership
- Use `@ObservedObject` for passed-down view models  
- Environment objects for dependency injection
- NotificationCenter for decoupled component communication

### Common Workflow
1. Make UI changes in SwiftUI views
2. Update view models for business logic
3. Add/modify GraphQL operations in `/GraphQL/` folder
4. Regenerate GraphQL code when schema changes
5. Test authentication flows thoroughly
6. Verify offline scenarios work correctly