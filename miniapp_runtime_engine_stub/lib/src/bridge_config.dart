class NativeBridgeConfig {
  final bool enableDeviceInfo;
  final bool enableUserInfo;
  final bool enableToast;
  final bool enableVibration;
  final bool enableShare;
  final bool enableCamera;
  final bool enableLocation;
  final bool enableFileSystem;
  final bool enableNotifications;
  final Map<String, Function(dynamic)> customMethods;

  const NativeBridgeConfig({
    this.enableDeviceInfo = true,
    this.enableUserInfo = true,
    this.enableToast = true,
    this.enableVibration = true,
    this.enableShare = true,
    this.enableCamera = false,
    this.enableLocation = false,
    this.enableFileSystem = false,
    this.enableNotifications = false,
    this.customMethods = const {},
  });
}
