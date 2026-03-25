# 🔧 MiniApp Runtime Engine Setup Guide

## Current Status
The Echat host app is currently using a **stub implementation** of the MiniApp Runtime Engine for testing purposes.

## When Your Actual Runtime Engine is Ready

### Option 1: Local Development (Recommended for Testing)
If your runtime engine is in a local directory:

1. **Update pubspec.yaml:**
   ```yaml
   dependencies:
     miniapp_runtime_engine:
       path: ../miniapp_runtime_engine  # Your actual engine path
   ```

2. **Remove the stub:**
   ```bash
   rm -rf miniapp_runtime_engine_stub
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

### Option 2: Published Package
If you've published your runtime engine to pub.dev:

1. **Update pubspec.yaml:**
   ```yaml
   dependencies:
     miniapp_runtime_engine: ^1.0.0  # Your version
   ```

2. **Remove the stub:**
   ```bash
   rm -rf miniapp_runtime_engine_stub
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

### Option 3: Git Repository
If your runtime engine is in a Git repository:

1. **Update pubspec.yaml:**
   ```yaml
   dependencies:
     miniapp_runtime_engine:
       git:
         url: https://github.com/your-org/miniapp_runtime_engine.git
         ref: main  # or specific tag/commit
   ```

2. **Remove the stub:**
   ```bash
   rm -rf miniapp_runtime_engine_stub
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

## What Your Runtime Engine Should Provide

Your MiniApp Runtime Engine should include these components:

### Core Widget
```dart
class MiniAppContainer extends StatefulWidget {
  final String url;
  final MiniAppConfig config;
  final NativeBridgeConfig bridgeConfig;
  final Function(bool)? onLoadingStateChanged;
  final Function(Object)? onError;
  final Function(Map<String, dynamic>)? onBridgeMessage;
  // ... constructor
}
```

### Configuration Classes
```dart
class MiniAppConfig {
  final bool enableJavaScript;
  final bool enableDomStorage;
  final bool allowFileAccess;
  // ... other security settings
}

class NativeBridgeConfig {
  final bool enableDeviceInfo;
  final bool enableUserInfo;
  final bool enableToast;
  // ... other bridge settings
}
```

### JavaScript Bridge
The container should inject a JavaScript bridge with these methods:
- `showToast(message)`
- `vibrate()`
- `getDeviceInfo()`
- `getUserInfo()`
- `share(content)`
- `requestCamera()`
- `requestLocation()`
- `log(message)`
- `testNative(data)`

## Testing the Integration

After setting up your actual runtime engine:

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Test with the HTML file:**
   - Open Mini Apps tab
   - Click 🧪 Test button
   - Load `test_miniapp.html` in a local server

3. **Verify bridge functionality:**
   - Check debug panel for bridge messages
   - Test all bridge methods
   - Verify error handling

## Troubleshooting

### "Package not found"
- Ensure the path to your runtime engine is correct
- Check that the runtime engine has a valid `pubspec.yaml`

### "Compilation errors"
- Verify your runtime engine exports the required classes
- Check that all dependencies are compatible

### "Bridge not working"
- Ensure JavaScript is enabled in your runtime engine
- Check that the bridge is properly injected
- Verify the bridge channel name matches

## Development Workflow

1. **Use stub** for initial UI testing
2. **Replace with actual engine** when ready
3. **Test bridge functionality** thoroughly
4. **Iterate** based on testing results

## Security Considerations

Your runtime engine should implement:
- ✅ Secure sandbox environment
- ✅ JavaScript execution control
- ✅ File access restrictions
- ✅ Network security policies
- ✅ Permission management

## Next Steps

1. ✅ **Current**: Using stub implementation
2. 🔄 **Next**: Replace with your actual runtime engine
3. 🎯 **Goal**: Full MiniApp testing environment

When your runtime engine is ready, simply update the pubspec.yaml path and remove the stub directory!
