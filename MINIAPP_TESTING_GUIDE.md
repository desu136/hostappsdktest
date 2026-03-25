# Echat Host App - MiniApp Testing Guide

## Overview

This guide explains how to use the Echat host app to test MiniApps developed with the `@ebisa-tesfaye/miniapp-sdk` npm package and powered by your MiniApp Runtime Engine.

## Setup Instructions

### 1. Install Dependencies

Make sure your MiniApp Runtime Engine is properly set up:

```bash
# In your echat project directory
flutter pub get
```

### 2. Runtime Engine Path

The app expects the MiniApp Runtime Engine at:
```
../miniapp_runtime_engine
```

Ensure this path points to your runtime engine directory.

## Testing MiniApps

### Method 1: Using Pre-configured MiniApps

1. Launch the Echat app
2. Navigate to the **Mini Apps** tab
3. Click on any pre-configured MiniApp card
4. The app will launch using your MiniAppContainer widget

### Method 2: Testing Custom URLs (Recommended for Development)

1. In the **Mini Apps** tab, click the **🧪 (Test)** button (second floating action button)
2. Enter your MiniApp details:
   - **Name**: Optional (e.g., "My Test App")
   - **URL**: Your MiniApp URL (e.g., `http://localhost:3000` or `http://192.168.1.10:8081/my-app`)
3. Click **Launch**

## MiniApp Development

### For Your Team Members

Your team can develop MiniApps using the npm SDK:

```bash
npm i @ebisa-tesfaye/miniapp-sdk
```

### Basic MiniApp Structure

```javascript
import { MiniAppSDK } from '@ebisa-tesfaye/miniapp-sdk';

// Initialize the SDK
const sdk = new MiniAppSDK();

// Test native bridge communication
sdk.showToast('Hello from MiniApp!');
sdk.vibrate();
sdk.getDeviceInfo();
sdk.getUserInfo();

// Share functionality
sdk.share({
  title: 'Check out my MiniApp!',
  text: 'Built with @ebisa-tesfaye/miniapp-sdk',
  url: window.location.href
});
```

## Native Bridge Features

The MiniAppContainer provides these bridge methods:

### 📱 Device & User Info
- `getDeviceInfo()` - Returns device information
- `getUserInfo()` - Returns user information
- `getHostInfo()` - Returns host app information

### 🎯 User Interaction
- `showToast(message)` - Shows native toast notification
- `vibrate()` - Triggers device vibration
- `share(content)` - Opens native share dialog

### 📸 Advanced Features
- `requestCamera()` - Request camera access
- `requestLocation()` - Request location access
- `openShareDialog(title, text, url)` - Share specific content

### 🧪 Testing & Debug
- `log(message)` - Log messages to host app
- `testNative(data)` - Test bridge communication

## Debug Features

### Bridge Message Monitoring

The host app displays all bridge messages in real-time:

1. Open any MiniApp
2. Bridge messages appear in the debug panel at the bottom
3. Click the **🐛 (Bug Report)** button to see detailed logs

### MiniApp Info

1. Click the **ℹ️ (Info)** button in the app bar
2. View MiniApp details, URL, and bridge statistics
3. Clear logs using the **Clear Logs** button

## URL Examples

### Local Development
```
http://localhost:3000
http://localhost:8080
http://127.0.0.1:3000
```

### Network Testing
```
http://192.168.1.10:8081/my-app
http://[your-ip]:3000
```

### Production URLs
```
https://my-miniapp.com
https://apps.example.com/my-app
```

## Security Features

The MiniAppContainer includes:

- ✅ Secure sandbox environment
- ✅ JavaScript enabled
- ✅ DOM storage enabled
- ❌ File access disabled (for security)
- ❌ Mixed content blocked
- ✅ Custom user agent identification

## Troubleshooting

### Common Issues

1. **MiniApp doesn't load**
   - Check the URL is correct and accessible
   - Ensure your development server is running
   - Verify network connectivity

2. **Bridge messages not working**
   - Check browser console for JavaScript errors
   - Ensure MiniApp SDK is properly imported
   - Verify bridge methods are called correctly

3. **Permission errors**
   - Some features (camera, location) require user permission
   - Check browser/OS permission settings

### Debug Tips

1. **Use browser developer tools** to inspect MiniApp
2. **Check the debug panel** for bridge messages
3. **Use the test button** to quickly iterate
4. **Monitor console logs** for JavaScript errors

## Best Practices

### For MiniApp Developers

1. **Always check bridge availability** before calling methods
2. **Handle errors gracefully** with try-catch blocks
3. **Test on different screen sizes** and orientations
4. **Optimize for mobile performance**
5. **Use semantic HTML** for better accessibility

### Example MiniApp Template

```html
<!DOCTYPE html>
<html>
<head>
    <title>My MiniApp</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="node_modules/@ebisa-tesfaye/miniapp-sdk/dist/index.js"></script>
</head>
<body>
    <div id="app">
        <h1>Welcome to My MiniApp!</h1>
        <button onclick="testBridge()">Test Bridge</button>
        <button onclick="showToast()">Show Toast</button>
    </div>

    <script>
        const sdk = new MiniAppSDK();

        function testBridge() {
            sdk.testNative('Hello from MiniApp!');
        }

        function showToast() {
            sdk.showToast('Hello from MiniApp!');
        }

        // Initialize
        document.addEventListener('DOMContentLoaded', () => {
            sdk.showToast('MiniApp loaded successfully!');
        });
    </script>
</body>
</html>
```

## Support

For issues related to:
- **MiniApp Runtime Engine**: Contact your runtime engine team
- **Host App**: Check this guide and debug features
- **MiniApp SDK**: Refer to SDK documentation

## Next Steps

1. ✅ Set up your development environment
2. ✅ Install the MiniApp SDK
3. ✅ Create a simple test MiniApp
4. ✅ Test using the Echat host app
5. ✅ Iterate and debug using built-in tools

Happy testing! 🚀
