import 'package:flutter/material.dart';
import 'package:flutter_rtmp_publisher/flutter_rtmp_publisher.dart';

class BroadcastScreen extends StatefulWidget {
  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final RTMPPublisher _publisher = RTMPPublisher();
  bool _isStreaming = false;

  Future<void> _startStreaming() async {
    await _publisher.startStream(
      rtmpUrl: "rtmp://VOTRE_IP/live/streamkey", // Remplacez par votre URL
    );
    setState(() => _isStreaming = true);
  }

  Future<void> _stopStreaming() async {
    await _publisher.stopStream();
    setState(() => _isStreaming = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Émetteur Live")),
      body: Center(
        child: Column(
          children: [
            if (_isStreaming)
              RTMPCameraPreview(_publisher),
            ElevatedButton(
              onPressed: _isStreaming ? _stopStreaming : _startStreaming,
              child: Text(_isStreaming ? "Arrêter" : "Commencer le Live"),
            ),
          ],
        ),
      ),
    );
  }
}
