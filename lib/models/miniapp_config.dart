/// Configuration for Mini-App WebView rendering behavior.
class MiniAppConfig {
  final bool enableJavaScript;
  final bool enableDomStorage;
  final bool allowFileAccess;
  final bool enableZoom;
  final bool debugMode;
  final String? userAgent;

  const MiniAppConfig({
    this.enableJavaScript = true,
    this.enableDomStorage = false,
    this.allowFileAccess = false,
    this.enableZoom = false,
    this.debugMode = false,
    this.userAgent,
  });
}

/// Configuration for the native bridge exposed to Mini-App web content.
class NativeBridgeConfig {
  final bool enableDeviceInfo;
  final bool enableUserInfo;
  final bool enableCamera;
  final bool enableLocation;
  final bool enableStorage;
  final bool enablePayments;
  final bool enableMessaging;

  const NativeBridgeConfig({
    this.enableDeviceInfo = false,
    this.enableUserInfo = false,
    this.enableCamera = false,
    this.enableLocation = false,
    this.enableStorage = false,
    this.enablePayments = false,
    this.enableMessaging = false,
  });
}
