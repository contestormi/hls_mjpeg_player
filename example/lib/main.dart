import 'package:flutter/material.dart';
import 'package:hls_mjpeg_player/hls_mjpeg_player.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FirstPage(),
    );
  }
}

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SizedBox(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PlayerPage(),
          ),
        ),
      ),
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  final controller = HlsMjpegPlayerController();
  final url = 'xxxxxx';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(() {
      print(controller.status);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller
      ..clearCache()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.width / 1.6,
              child: Stack(
                children: [
                  HlsMjpegPlayer(url: url),
                  ListenableBuilder(
                    listenable: controller,
                    builder: (context, child) {
                      if (controller.status == HlsMjpegPlayerStatus.loading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, child) {
                if (controller.status == HlsMjpegPlayerStatus.play) {
                  return ElevatedButton(
                    onPressed: controller.pause,
                    child: const Icon(Icons.pause),
                  );
                } else if (controller.status == HlsMjpegPlayerStatus.pause) {
                  return ElevatedButton(
                    onPressed: () => controller.play(url),
                    child: const Icon(Icons.play_arrow),
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
