# Firebase AI: Gemini 3 Flash Preview - Global Location Configuration

When using the `gemini-3-flash-preview` model with the `firebase_ai` package in a Flutter application, it is crucial to explicitly specify the `location` parameter as `'global'` when initializing the `FirebaseAI.vertexAI()` instance.

**Problem:**
Attempts to use `gemini-3-flash-preview` without specifying `location: 'global'` (or with a region like `us-central1`) result in a "Publisher Model was not found or your project does not have access to it" error. This occurs even after enabling the Vertex AI API in the Google Cloud project.

**Solution:**
Modify the `_createGenerativeModel()` function (or equivalent initialization logic) in `lib/ui/assistant_screen.dart` to include `location: 'global'` in the `FirebaseAI.vertexAI()` call.

**Example Code Snippet:**

```dart
GenerativeModel _createGenerativeModel() {
  // ... (tool declarations) ...

  return FirebaseAI.vertexAI(location: 'global').generativeModel(
    model: 'gemini-3-flash-preview',
    tools: [Tool.functionDeclarations(validTools)],
  );
}
```

**Reasoning:**
While `gemini-3-flash-preview` is available, its deployment or access mechanism through `firebase_ai` (which leverages Vertex AI) may require the `global` location endpoint for successful instantiation, especially during preview phases or for certain project configurations. This ensures the SDK correctly routes the request to the globally accessible model endpoint.
