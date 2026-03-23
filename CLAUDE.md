# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Teki is a Flutter-based mobile application for business management, including sales, inventory, customers, suppliers, and financial reporting. The app follows Clean Architecture principles with a clear separation of data, domain, and presentation layers.

## Development Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons:main

# Run the application
flutter run

# Build for production
flutter build apk
flutter build ios
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format .
```

### Testing
```bash
# Run tests
flutter test
```

## Architecture

### Clean Architecture Structure
The project follows Clean Architecture with three main layers:

- **Data Layer** (`lib/src/data/`): External data sources, repositories implementations, and models
- **Domain Layer** (`lib/src/domain/`): Business logic, abstract repositories, and use cases
- **Presentation Layer** (`lib/src/presentation/`): UI screens, widgets, and state management

### Key Architectural Components

#### State Management
- **Riverpod**: Primary state management solution using `flutter_riverpod` and `hooks_riverpod`
- **GetX**: Used for navigation and route management
- Provider containers are configured in `main.dart` with a global container

#### Navigation
- **GetX Navigation**: Configured in `lib/src/routes/app_routes.dart`
- **Middleware**: Authentication middleware applied to all routes
- Route observer for tracking navigation events

#### API Integration
- **Dio**: HTTP client configured in `lib/src/utils/api_client.constant.dart`
- Automatic token injection via interceptors
- Automatic logout on 401 responses
- Base URL configured via environment variables

### Directory Structure

#### Core Directories
- `lib/src/data/`: Data layer with datasources, models, and repository implementations
- `lib/src/domain/`: Domain layer with abstract repositories and business logic
- `lib/src/presentation/`: UI layer with screens, widgets, and sections
- `lib/src/providers/`: Riverpod providers for state management
- `lib/src/routes/`: Navigation routes and middleware
- `lib/src/shared/`: Shared services and utilities
- `lib/src/utils/`: Utility functions and constants

#### Screen Organization
Each major feature has its own directory under `presentation/screens/` with:
- Main screen file
- Sections subdirectory for screen components
- Widgets subdirectory for reusable components

## Key Technologies

### Core Dependencies
- **Flutter**: Mobile framework
- **flutter_riverpod** & **hooks_riverpod**: State management
- **get**: Navigation and route management
- **dio**: HTTP client for API communication
- **flutter_dotenv**: Environment variable management

### UI/UX Libraries
- **google_fonts**: Typography
- **flutter_svg**: SVG support
- **fl_chart**: Data visualization
- **convex_bottom_bar**: Custom navigation bars
- **cherry_toast**: Toast notifications

### Utility Libraries
- **shared_preferences**: Local storage
- **image_picker**: Image selection
- **pdf** & **printing**: PDF generation and printing
- **syncfusion_flutter_pdfviewer**: PDF viewing

## Environment Configuration

### Environment Variables
Create a `.env` file in the root directory with:
```
API_URL=your_api_base_url
```

The environment is loaded in `main.dart` via `Environment.intiEnvironment()`.

## Development Guidelines

### Model Organization
- **Teki Models**: Core business entities in `data/models/teki_model/`
- **Feature Models**: Organized by feature (products, sales, customers, etc.)
- **Response Models**: API response wrappers in `data/models/response/`

### Provider Pattern
- Providers are organized by feature in `lib/src/providers/`
- Use Riverpod for state management
- Authentication state is managed globally

### API Integration
- All API calls use the configured Dio client
- Automatic token management via interceptors
- Environment-based URL configuration

### Localization
- Spanish is the primary locale (`es`)
- English is supported as secondary locale
- Date formatting is configured for Spanish locale

## Current Development Branch
- Main development branch: `develop`
- Current working branch: `version-final-venta`

## Modified Files
The git status shows modifications in:
- `lib/src/presentation/screens/comprobantes/comprobante_screen.dart/view_comprobante_screen.dart`
- `lib/src/presentation/screens/comprobantes/comprobante_screen.dart/product_list.dart` (untracked)