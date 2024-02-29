import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    _controller = CameraController(
      cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front),
      ResolutionPreset.medium,
    );
    _controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      _startTimer();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      _captureAndSendPhoto();
    });
  }

  Future<void> _captureAndSendPhoto() async {
    try {
      final XFile photo = await _controller!.takePicture();
      final File file = File(photo.path);

      // Create a multipart request
      var request = http.MultipartRequest('POST', Uri.parse('http://192.168.1.101:8080/documentos/upload'));

      // Add file to the request
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Send request
      var response = await request.send();

      // Get response
      final responseBody = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');
    } catch (e) {
      print('Error capturing and sending photo: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: CameraPreview(_controller!),
    );
  }
}