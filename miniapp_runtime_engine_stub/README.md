# MiniApp Runtime Engine - Stub Implementation

This is a temporary stub implementation. Replace this with your actual MiniApp Runtime Engine.

## Installation

This package provides:
- MiniAppContainer widget
- MiniAppConfig class
- NativeBridgeConfig class
- Bridge message handling

## Usage

```dart
import 'package:miniapp_runtime_engine/miniapp_runtime_engine.dart';

MiniAppContainer(
  url: 'https://your-miniapp.com',
  config: MiniAppConfig(...),
  bridgeConfig: NativeBridgeConfig(...),
  onBridgeMessage: (message) => handleBridgeMessage(message),
)
```
