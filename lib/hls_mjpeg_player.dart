import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HlsMjpegPlayerStatus {
  loading,
  play,
  pause,
  error,
  undefine,
}

class HlsMjpegPlayerController extends ChangeNotifier {
  final _mChannel = const MethodChannel('com.example.hls_mjpeg_player');
  HlsMjpegPlayerStatus _status = HlsMjpegPlayerStatus.undefine;

  HlsMjpegPlayerController() {
    _mChannel.setMethodCallHandler((call) async {
      if (call.method == 'onStatusChange') {
        final status = call.arguments['status'] as String? ?? '';
        if (status.isNotEmpty) {
          _status = switch (status) {
            'Loading' => HlsMjpegPlayerStatus.loading,
            'Play' => HlsMjpegPlayerStatus.play,
            'Pause' => HlsMjpegPlayerStatus.pause,
            'Error' => HlsMjpegPlayerStatus.error,
            _ => HlsMjpegPlayerStatus.undefine,
          };
          notifyListeners();
        }
      }
    });
  }

  HlsMjpegPlayerStatus get status => _status;

  Future<void> pause() => _mChannel.invokeMethod('pause');

  Future<void> play(String url) => _mChannel.invokeMethod('play', {'url': url});

  Future<void> clearCache() => _mChannel.invokeMethod('clearCache');
}

class HlsMjpegPlayer extends StatelessWidget {
  final String url;

  const HlsMjpegPlayer({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: 'HlsMjpegPlayer',
          layoutDirection: TextDirection.ltr,
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: {'url': url},
        );
      case TargetPlatform.android:
        return AndroidView(
          viewType: 'HlsMjpegPlayer',
          layoutDirection: TextDirection.ltr,
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: {'url': url},
        );
      default:
        throw UnsupportedError('Unsupported');
    }
  }
}
