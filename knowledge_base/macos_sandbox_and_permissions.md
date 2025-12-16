# Knowledge: macOS App Sandbox & Permissions

**Date**: 2025-12-16
**Context**: Discovered while implementing file-system handover and debugging microphone permissions for the Flutter macOS app.

## The Finding
Disabling the **App Sandbox** (`com.apple.security.app-sandbox = false`) in macOS entitlements resolves two distinct classes of issues for internal/developer builds:

1.  **File System Access**: It allows the app to write to arbitrary paths (like the workspace `to_dos/` directory) without requiring `NSOpenPanel` user interaction or "User Selected File" entitlements.
2.  **Permission Plugins**: It resolves `MissingPluginException` errors when requesting sensitive permissions (Microphone, Camera). In a sandboxed environment, if entitlements or signing are slightly misconfigured, the OS blocks the permission request *before* it reaches the plugin, causing the plugin to crash or return a "missing implementation" error.

## Implication for Development
For internal tools or "autonomous" apps that need to interact with the developer's environment (like this project):
-   **Debug/Profile Builds**: Explicitly **DISABLE** the sandbox in `DebugProfile.entitlements`. This grants "God Mode" access to the filesystem and hardware, simplifying development.
-   **Release/Store Builds**: MUST have the sandbox enabled. This requires careful configuration of `Network Client`, `Audio Input`, and `User Selected File` entitlements.

## Configuration
**File**: `macos/Runner/DebugProfile.entitlements`
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

## Related Errors
- `OS Error: Operation not permitted, errno = 1` (File System)
- `MissingPluginException(No implementation found for method requestPermissions)` (Microphone/Camera)

