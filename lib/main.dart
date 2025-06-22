import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  runApp(const MyApp());
  // Initialisation des renderers WebRTC
  RTCVideoRenderer.registerWith();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Streaming App',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Streaming Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BroadcastScreen()),
              ),
              child: const Text('Démarrer un Live'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewerScreen()),
              ),
              child: const Text('Rejoindre un Live'),
            ),
          ],
        ),
      ),
    );
  }
}

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': 1280,
          'height': 720,
          'frameRate': 30,
        },
      });
      
      _localRenderer.srcObject = _localStream;
      _peerConnection = await _createPeerConnection();
      
      // Ajoute le stream local à la connexion
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      setState(() => _isConnected = true);
      
    } catch (e) {
      print('Erreur WebRTC: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        // Optionnel: Ajouter un serveur TURN si nécessaire
        // {'urls': 'turn:your_turn_server', 'username': 'user', 'credential': 'pass'}
      ]
    };

    final pc = await createPeerConnection(config);
    
    pc.onIceCandidate = (candidate) {
      // Envoyer le candidat ICE à l'autre pair via votre serveur de signalisation
      print('Nouveau candidat ICE: $candidate');
    };

    pc.onConnectionState = (state) {
      print('État de connexion: $state');
    };

    return pc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Émetteur Live'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.videocam : Icons.videocam_off),
            onPressed: () => _initWebRTC(),
          ),
        ],
      ),
      body: Center(
        child: _isConnected
            ? RTCVideoView(_localRenderer)
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> _initWebRTC() async {
    await _remoteRenderer.initialize();
    
    try {
      _peerConnection = await _createPeerConnection();
      
      _peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video') {
          setState(() {
            _remoteRenderer.srcObject = event.streams.first;
            _isConnected = true;
          });
        }
      };

      // Ici: Ajouter la logique de signalisation pour se connecter au broadcaster
      
    } catch (e) {
      print('Erreur WebRTC: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    return await createPeerConnection(config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spectateur Live')),
      body: Center(
        child: _isConnected
            ? RTCVideoView(_remoteRenderer)
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Connexion au stream...'),
                ],
              ),
      ),
    );
  }
}
