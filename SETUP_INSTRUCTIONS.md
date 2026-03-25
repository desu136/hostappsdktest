# 🚀 Echat Host App Setup for MiniApp Testing

## Quick Start

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Test MiniApps**
   - Open the **Mini Apps** tab
   - Click the **🧪 Test** button
   - Enter `http://localhost:3000` or load `test_miniapp.html` in a local server

## For Your Development Team

### MiniApp Development Workflow

1. **Install MiniApp SDK**
   ```bash
   npm i @ebisa-tesfaye/miniapp-sdk
   ```

2. **Create Test MiniApp**
   - Use the provided `test_miniapp.html` as a template
   - Or create your own with the SDK

3. **Test in Host App**
   - Start your local development server
   - Use the **🧪 Test** button in Echat
   - Enter your local URL (e.g., `http://localhost:3000`)

### Replacing the Stub Runtime Engine

When your actual MiniApp Runtime Engine is ready:

1. **Update pubspec.yaml**
   ```yaml
   dependencies:
     miniapp_runtime_engine:
       path: ../miniapp_runtime_engine  # Your actual engine
   ```

2. **Remove the stub**
   ```bash
   rm -rf miniapp_runtime_engine_stub
   ```

3. **Run flutter pub get**
   ```bash
   flutter pub get
   ```

## Bridge API Reference

The MiniAppContainer provides these bridge methods:

### Basic Communication
- `showToast(message)` - Display toast notification
- `vibrate()` - Vibrate device
- `log(message)` - Log to host app

### Information
- `getDeviceInfo()` - Get device information
- `getUserInfo()` - Get user information  
- `getHostInfo()` - Get host app information

### Advanced Features
- `share(content)` - Share content
- `requestCamera()` - Request camera access
- `requestLocation()` - Request location access

### Testing
- `testNative(data)` - Test bridge communication

## Security Configuration

The MiniAppContainer includes these security features:

- ✅ Secure sandbox environment
- ✅ JavaScript enabled
- ✅ DOM storage enabled
- ❌ File access disabled (security)
- ❌ Mixed content blocked
- ✅ Custom user agent

## Debug Features

1. **Real-time Bridge Monitoring**
   - All bridge messages displayed in debug panel
   - Timestamp and message content

2. **MiniApp Info Dialog**
   - Click ℹ️ button for detailed info
   - View URL, bridge stats, and clear logs

3. **Debug Information**
   - Click 🐛 button for comprehensive debug data
   - Full bridge message history

## Testing URLs

### Local Development
```
http://localhost:3000
http://127.0.0.1:3000
file:///path/to/test_miniapp.html
```

### Network Testing
```
http://192.168.1.10:8081/my-app
http://[your-ip]:3000
```

## Common Issues & Solutions

### "Bridge not available"
- Ensure MiniApp Runtime Engine is properly installed
- Check that JavaScript is enabled
- Verify the MiniApp URL is accessible

### "MiniApp doesn't load"
- Check the URL is correct
- Ensure your development server is running
- Verify network connectivity

### Bridge messages not working
- Check browser console for JavaScript errors
- Ensure SDK is properly imported
- Verify bridge method calls

## Next Steps

1. ✅ Set up development environment
2. ✅ Test with provided HTML file
3. ✅ Integrate your actual MiniApp Runtime Engine
4. ✅ Develop and test your team's MiniApps
5. ✅ Iterate using debug features

## Support

- **Runtime Engine Issues**: Contact your runtime engine team
- **Host App Issues**: Check debug features and this guide
- **MiniApp SDK Issues**: Refer to SDK documentation

Happy testing! 🎉
