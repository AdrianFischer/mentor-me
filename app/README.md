# flutter_app

A new Flutter project.

## Configuration

This project uses `flutter_dotenv` to manage environment variables.

1.  **Create a `.env` file** in the root of the project (this file is git-ignored).
2.  Add your keys:

```env
GEMINI_API_KEY=your_api_key_here
SCREENSHOT_DIR=/path/to/screenshots
```

3.  Run the app normally:

```bash
flutter run
```

### Fallback (CI/CD)

The configuration system also supports `--dart-define` as a fallback if the `.env` variable is missing.

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key
```

### Environment Variables

| Variable | Description |
|Data | |
| `GEMINI_API_KEY` | API Key for Google Gemini AI |
| `SCREENSHOT_DIR` | Directory to save automated screenshots (used in `main_dev.dart`) |

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
