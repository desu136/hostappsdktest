class MiniAppConfig {
  final bool enableJavaScript;
  final bool enableDomStorage;
  final bool allowFileAccess;
  final bool allowInlineMediaPlayback;
  final String userAgent;
  final bool allowMixedContent;
  final bool enableZoom;
  final bool debugMode;

  const MiniAppConfig({
    this.enableJavaScript = true,
    this.enableDomStorage = true,
    this.allowFileAccess = false,
    this.allowInlineMediaPlayback = true,
    this.userAgent = 'MiniApp-Container/1.0',
    this.allowMixedContent = false,
    this.enableZoom = false,
    this.debugMode = false,
  });
}
