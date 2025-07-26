
![SolveNote Banner](assets\images\SolveNoteBanner.jpg)

# SolveNote

AI-powered math notes app with handwriting recognition that solves equations instantly—just write, and it computes. 

## Overview

SolveNote is a cross-platform notes application designed specifically for math. Built on the foundation of the popular Saber notes app, SolveNote adds powerful math recognition capabilities that can instantly solve handwritten equations and provide step-by-step solutions.

### Key Features

- Write equations by hand and get instant solutions
- Full-stack notes app with all the tools you need whether your solving a problem or taking notes for a class
- Currnetly Available on Android and web (demo). iOS, Windows, macOS, Linux support coming soon!
- Synchronize your work across all your devices via Nextcloud
- Dark mode! Comfortably take notes in any lighting condition
- Import and annotate PDFs with full math recognition capabilities

## Math Recognition Features

- Write your equations/expressions naturally with pen/stylus/finger?
- Bounding box technology will instantly detect and group related strokes and identify your written equation
- Press `Solve` to get the answer and view detailed solving steps (with LaTeX formatting)
- Supports algebra, calculus, trigonometry, and more
- You can manually select strokes with lasso tool to solve specific equations (or if bounding box fails to detect your equation)

## Installation

### Prerequisites

- **Flutter SDK**: Version 3.19.0 or higher
- **Dart SDK**: Version 3.0.0 or higher
- **Platform-specific dependencies** (see below)

### From Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/saber-notes/saber.git
   cd saber
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up API key** (for math recognition)
   ```bash
   # For local development
   flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
   
   # For production builds
   flutter build web --dart-define=GEMINI_API_KEY=your_api_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
```bash
flutter build apk --release
```

#### Web
```bash
flutter build web --release
```

### Pre-built Binaries

#### Android
- **Google Play Store**: [Coming Soon]
- **F-Droid**: [Coming Soon]
- **Direct APK**: Download from [GitHub Releases](https://github.com/saber-notes/saber/releases)

#### Web
- **Live Demo**: [https://solvenote-7a7b2.web.app](https://solvenote-7a7b2.web.app)

## Usage Guide

### Getting Started

1. **Create a New Note**
   - Tap the "+" button to create a new note
   - Choose from various paper styles and backgrounds

2. **Write Mathematical Expressions**
   - Use the pen or pencil tool to write equations
   - Write naturally - it will detect mathematical content automatically

3. **Solve Equations**
   - Tap the "Solve" button that appears on detected expressions
   - View the solution and step-by-step explanation
   - Tap the expression again to hide/show the solution


## Configuration

### API Key Setup

To enable math recognition, you need a Google Gemini API key:

1. **Get API Key**
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key
   - Copy the key for use in SolveNote

2. **Configure the App**
   - For development: Use `--dart-define=GEMINI_API_KEY=your_key`
   - For production: Set environment variable or build-time define

### Customization

#### Themes
- **Light Mode**: Traditional white background
- **Dark Mode**: Inverted colors for low-light environments
- **Dynamic Colors**: Automatic theme adaptation (Android 12+)

#### Tools
- **Pen Types**: Fountain pen, ballpoint pen, shape pen
- **Colors**: Customizable color palette
- **Sizes**: Adjustable stroke width
- **Pressure Sensitivity**: Support for pressure-sensitive devices

## Development

### Project Structure

```
lib/
├── components/          # UI components
│   ├── canvas/         # Drawing canvas and tools
│   ├── home/           # Home screen components
│   └── settings/       # Settings and configuration
├── data/               # Data layer
│   ├── math/           # Math recognition logic
│   ├── nextcloud/      # Cloud sync functionality
│   └── tools/          # Drawing tools
├── pages/              # Main app pages
└── i18n/               # Internationalization
```

### Key Components

#### Math Recognition System
- `MathRecognizer`: Handles API communication with Gemini
- `MathExpressionAnalyzer`: Detects and groups mathematical strokes
- `MathExpressionOverlay`: UI for displaying solutions

#### Drawing System
- `Canvas`: Main drawing surface with gesture handling
- `Stroke`: Represents individual pen strokes
- `Tool`: Abstract base for different drawing tools

### Building for Development

```bash
# Debug build
flutter run

# Release build
flutter build [platform] --release

# With math recognition enabled
flutter run --dart-define=GEMINI_API_KEY=your_key
```


## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

- **Saber Notes**: Built on the excellent foundation of the Saber notes app
- **Open Source Community**: All the amazing packages and tools that make this possible
