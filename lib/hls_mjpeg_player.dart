import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum MjpegPlayerStatus {
  loading,
  play,
  pause,
  error,
  undefine,
}

class MjpegPlayerController extends ChangeNotifier {
  final _mChannel = const MethodChannel('com.example.hls_mjpeg_player');
  MjpegPlayerStatus _status = MjpegPlayerStatus.undefine;

  MjpegPlayerController() {
    _mChannel.setMethodCallHandler((call) async {
      if (call.method == 'onStatusChange') {
        final status = call.arguments['status'] as String? ?? '';
        if (status.isNotEmpty) {
          _status = switch (status) {
            'Loading' => MjpegPlayerStatus.loading,
            'Play' => MjpegPlayerStatus.play,
            'Pause' => MjpegPlayerStatus.pause,
            'Error' => MjpegPlayerStatus.error,
            _ => MjpegPlayerStatus.undefine,
          };
          notifyListeners();
        }
      }
    });
  }

  MjpegPlayerStatus get status => _status;

  Future<void> pause() => _mChannel.invokeMethod('pause');

  Future<void> play(String url) => _mChannel.invokeMethod('play', {'url': url});
}

class MjpegPlayer extends StatelessWidget {
  final String url;

  const MjpegPlayer({
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
