import 'package:flutter/services.dart';

/// Reads the one-shot URL deposited by the iOS Share Extension.
///
/// The extension only stores a small, validated payload in the App Group. The
/// app validates it again before it becomes part of the wishlist flow.
class ShareIntentService {
  const ShareIntentService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.dodopok.lume/share';
  static const _consumePendingUrlMethod = 'consumePendingUrl';
  static const _maxUrlLength = 4096;

  final MethodChannel _channel;

  Future<Uri?> consumePendingUrl() async {
    try {
      final raw = await _channel.invokeMethod<String>(_consumePendingUrlMethod);
      return validateUrl(raw);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Uri? validateUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty || value.length > _maxUrlLength) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
    if (uri.userInfo.isNotEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }
}
