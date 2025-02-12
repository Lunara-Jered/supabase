import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://leuxlvlrpumzmgkyqtfd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxldXhsdmxycHVtem1na3lxdGZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkzNjI4MjcsImV4cCI6MjA1NDkzODgyN30.JNSdrlOvmPRKBNE3J1bucZOWrqIkA3zteGnPu1Wgzkw',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    VideoUploadPage(),
    PDFUploaderScreen(),
    StoryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.white,
        title: Image.asset("assets/banner.png", height: 40),
      ),
      body: Column(
        children: [
          const StorySection(), // Ajout de la section stories sous l'AppBar
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({super.key, required this.currentIndex, required this.onItemTapped});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  String type = 'video';  // Exemple de variable pour gérer l'état

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: widget.currentIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.image_aspect_ratio), label: "Actualités"),
        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Décryptages"),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: "FAQ"),
        BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: "Lois Électorales"),
      ],
      onTap: (index) {
        widget.onItemTapped(index);
        setState(() {
          type = 'pdf';  // Exemple de changement de l'état en fonction de l'index
        });
      },
    );
  }
}

class VideoUploadPage extends StatefulWidget {
  @override
  _VideoUploadPageState createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  final _titleController = TextEditingController();
  File? _selectedThumbnail;
  File? _selectedVideo;

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _selectedThumbnail = File(pickedFile.path);
      }
    });
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();  // Use ImagePicker for both images and videos
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _selectedVideo = File(pickedFile.path);
      }
    });
  }

  Future<void> _uploadToSupabase() async {
    if (_selectedVideo == null || _selectedThumbnail == null || _titleController.text.isEmpty) {
      return;
    }

    // Demander la permission de stockage
    Permission.storage.request();

    // Upload des fichiers
    final thumbnailPath = 'thumbnails/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final videoPath = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';

    // Upload Thumbnail
    final thumbnailFile = _selectedThumbnail!;
    final videoFile = _selectedVideo!;

    final thumbnailResponse = await Supabase.instance.client.storage
        .from('video-bucket') // Remplace avec ton bucket
        .upload(thumbnailPath, thumbnailFile);

    final videoResponse = await Supabase.instance.client.storage
        .from('video-bucket') // Remplace avec ton bucket
        .upload(videoPath, videoFile);

    if (thumbnailResponse.error == null && videoResponse.error == null) {
      // Insertion dans la base de données
      final videoData = {
        'title': _titleController.text,
        'video_path': videoResponse.data['Key'],
        'thumbnail_path': thumbnailResponse.data['Key'],
      };

      final response = await Supabase.instance.client
          .from('videos')
          .insert([videoData])
          .execute();

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vidéo téléchargée avec succès!')));
        setState(() {
          _selectedThumbnail = null;
          _selectedVideo = null;
          _titleController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${response.error!.message}')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de téléchargement')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Télécharger une Vidéo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Titre de la vidéo'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickThumbnail,
              child: Text('Choisir Miniature'),
            ),
            if (_selectedThumbnail != null) Image.file(_selectedThumbnail!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text('Choisir Vidéo'),
            ),
            if (_selectedVideo != null) Text('Vidéo sélectionnée'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploadToSupabase,
              child: Text('Télécharger sur Supabase'),
            ),
          ],
        ),
      ),
    );
  }
}

class PDFUploaderScreen extends StatefulWidget {
  @override
  _PDFUploaderScreenState createState() => _PDFUploaderScreenState();
}

class _PDFUploaderScreenState extends State<PDFUploaderScreen> {
  bool _isUploading = false;
  String _uploadStatus = "";

  // Fonction pour télécharger le PDF dans Supabase
  Future<void> _uploadPDF() async {
    // Ouvrir un sélecteur de fichiers pour choisir un PDF
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);

      // Commencer l'upload
      setState(() {
        _isUploading = true;
        _uploadStatus = "Téléchargement en cours...";
      });

      // Télécharger le fichier dans le bucket "pdf_files" sur Supabase
      final fileName = result.files.single.name;
      final fileBytes = await file.readAsBytes();

      final response = await Supabase.instance.client
          .storage
          .from('pdf_files')  // Assurez-vous que le nom du bucket est correct
          .upload(fileName, fileBytes, upsert: true);

      if (response.error == null) {
        setState(() {
          _uploadStatus = "PDF téléchargé avec succès!";
        });
      } else {
        setState(() {
          _uploadStatus = "Erreur lors du téléchargement : ${response.error?.message}";
        });
      }
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Téléchargement PDF")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploading) CircularProgressIndicator(),
            if (!_isUploading) ElevatedButton(
              onPressed: _uploadPDF,
              child: Text("Choisir et Télécharger un PDF"),
            ),
            SizedBox(height: 20),
            Text(_uploadStatus),
          ],
        ),
      ),
    );
  }
}

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          StoryCard(imageUrl: 'assets/story1.jpg', title: 'Story 1'),
          StoryCard(imageUrl: 'assets/story2.jpg', title: 'Story 2'),
          StoryCard(imageUrl: 'assets/story3.jpg', title: 'Story 3'),
        ],
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const StoryCard({super.key, required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Column(
        children: [
          Image.asset(imageUrl, width: 100, height: 100),
          Text(title),
        ],
      ),
    );
  }
}

class AddFeedItemScreen extends StatefulWidget {
  @override
  _AddFeedItemScreenState createState() => _AddFeedItemScreenState();
}

class _AddFeedItemScreenState extends State<AddFeedItemScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  String? imageUrl;
  String? pdfUrl;
  String? videoUrl;
  String type = 'image';

  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;

  // Choisir une image
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageUrl = pickedFile.path;
      });
    }
  }

  // Choisir une vidéo
  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        videoUrl = pickedFile.path;
        _videoController = VideoPlayerController.file(File(pickedFile.path))
          ..initialize().then((_) {
            setState(() {});
            _videoController?.play();
          });
      });
    }
  }

  // Choisir un PDF
  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() {
        pdfUrl = result.files.single.path;
      });
    }
  }

  // Ajouter un élément feed
  Future<void> _addFeedItem() async {
    if (imageUrl != null || pdfUrl != null || videoUrl != null) {
      await _supabaseService.addFeedItem(imageUrl ?? '', pdfUrl ?? '', videoUrl ?? '', type);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Élément ajouté')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez sélectionner un fichier')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajouter un élément')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(onPressed: _pickImage, child: Text('Choisir une image')),
                SizedBox(width: 10),
                ElevatedButton(onPressed: _pickVideo, child: Text('Choisir une vidéo')),
                SizedBox(width: 10),
                ElevatedButton(onPressed: _pickPdf, child: Text('Choisir un PDF')),
              ],
            ),
            SizedBox(height: 20),
            Text('Type :'),
            Row(
              children: [
                Radio(value: 'image', groupValue: type, onChanged: (value) => setState(() => type = value as String)),
                Text('Image'),
                Radio(value: 'video', groupValue: type, onChanged: (value) => setState(() => type = value as String)),
                Text('Vidéo'),
                Radio(value: 'pdf', groupValue: type, onChanged: (value) => setState(() => type = value as String)),
                Text('PDF'),
              ],
            ),
            SizedBox(height: 20),
            if (imageUrl != null)
              Image.file(File(imageUrl!)),
            if (videoUrl != null && _videoController != null)
              VideoPlayer(_videoController!),
            if (pdfUrl != null)
              Text('PDF sélectionné'),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _addFeedItem, child: Text('Ajouter à la base de données')),
          ],
        ),
      ),
    );
  }
}
