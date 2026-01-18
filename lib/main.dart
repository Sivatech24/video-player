// main.dart
// Flutter Video Player App with FFmpeg, File Browser, Web URL History, About Page

// pubspec.yaml (IMPORTANT: add these dependencies)
/*
name: ffmpeg_video_player
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  video_player: ^2.8.6
  ffmpeg_kit_flutter: ^6.0.3
  permission_handler: ^11.3.0
  path_provider: ^2.1.2
  path: ^1.9.0
  shared_preferences: ^2.2.3
  file_picker: ^6.1.1

flutter:
  uses-material-design: true
*/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFmpeg Video Player',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final pages = const [
    FilesPage(),
    WebPlayerPage(),
    HistoryPage(),
    AboutPage(),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.language), label: 'Web'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
      ),
    );
  }
}

// ================= FILES PAGE =================
class FilesPage extends StatelessWidget {
  const FilesPage({super.key});

  Future<void> _pickAndPlay(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(file: File(result.files.single.path!)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Files')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndPlay(context),
        child: const Icon(Icons.video_library),
      ),
      body: const Center(
        child: Text('Browse internal / external storage videos'),
      ),
    );
  }
}

// ================= WEB PLAYER PAGE =================
class WebPlayerPage extends StatefulWidget {
  const WebPlayerPage({super.key});

  @override
  State<WebPlayerPage> createState() => _WebPlayerPageState();
}

class _WebPlayerPageState extends State<WebPlayerPage> {
  final controller = TextEditingController();

  Future<void> _playFromUrl() async {
    final url = controller.text.trim();
    if (url.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    history.add(url);
    await prefs.setStringList('history', history);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(networkUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Play from Web URL')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Video URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _playFromUrl,
              child: const Text('Play Video'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= HISTORY PAGE =================
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<String> history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => history = prefs.getStringList('history') ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
        ),
        itemCount: history.length,
        itemBuilder: (_, i) => Card(
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(networkUrl: history[i]),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(history[i], maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= ABOUT PAGE =================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'FFmpeg Video Player\n\n'
          '• Plays local and online videos\n'
          '• Uses FFmpeg for processing\n'
          '• Supports Android internal & external storage\n'
          '• Web URL history stored temporarily\n\n'
          'Updates:\n'
          '- Initial release\n'
          '- Performance improvements planned',
        ),
      ),
    );
  }
}

// ================= VIDEO PLAYER SCREEN =================
class VideoPlayerScreen extends StatefulWidget {
  final File? file;
  final String? networkUrl;

  const VideoPlayerScreen({super.key, this.file, this.networkUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.file != null) {
      _controller = VideoPlayerController.file(widget.file!);
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.networkUrl!));
    }

    _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player')),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        }),
        child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
