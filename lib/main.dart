import 'package:flutter_webrtc/flutter_webrtc.dart';

class BroadcastScreen extends StatefulWidget {
  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    _localRenderer.srcObject = _localStream;

    // Configurez le serveur WebRTC ici (ex: mediasoup ou un serveur public)
    _peerConnection = await _createPeerConnection();
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    // Remplacez par la config de votre serveur WebRTC
    return await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}, // STUN gratuit de Google
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RTCVideoView(_localRenderer),
    );
  }
}
