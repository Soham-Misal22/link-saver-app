import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Link Saver',
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
  List<Map<String, dynamic>> _folders = [];
  final TextEditingController _textFieldController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  String? _sharedUrl;

  @override
  void initState() {
    super.initState();
    _refreshFolders();

    // Handle shared text/links
    ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && mounted) {
        setState(() {
          // Extract text from shared media
          _sharedUrl = value[0].path;
          _showSaveLinkDialog();
        });
      }
    }, onError: (err) {
      print("getMediaStream error: ");
    });

    // Handle initial shared text
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && mounted) {
        setState(() {
          _sharedUrl = value[0].path;
          _showSaveLinkDialog();
        });
      }
    });
  }

  void _refreshFolders() async {
    final data = await DatabaseHelper.instance.getFolders();
    setState(() {
      _folders = data;
    });
  }

  Future<void> _showAddFolderDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a new folder'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: "Folder Name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('ADD'),
              onPressed: () async {
                await DatabaseHelper.instance.add({
                  'name': _textFieldController.text,
                });
                _textFieldController.clear();
                Navigator.pop(context);
                _refreshFolders();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddLinkDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(hintText: "Paste your link here"),
              ),
              const SizedBox(height: 16),
              const Text("Select folder:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_folders.isEmpty)
                const Text("No folders found. Create one first.", 
                         style: TextStyle(color: Colors.grey))
              else
                ..._folders.map((folder) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(folder['name']),
                  onTap: () async {
                    await _saveLinkToFolder(folder['id'], _linkController.text);
                    _linkController.clear();
                    Navigator.pop(context);
                  },
                )),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSaveLinkDialog() async {
    if (_sharedUrl == null) return;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Save Link To..."),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Link: ", 
                   maxLines: 3, 
                   overflow: TextOverflow.ellipsis,
                   style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              const Text("Select folder:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_folders.isEmpty)
                const Text("No folders found. Create one first.", 
                         style: TextStyle(color: Colors.grey))
              else
                ..._folders.map((folder) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(folder['name']),
                  onTap: () async {
                    await _saveLinkToFolder(folder['id'], _sharedUrl!);
                    Navigator.pop(context);
                    _sharedUrl = null;
                  },
                )),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () {
                Navigator.pop(context);
                _sharedUrl = null;
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveLinkToFolder(int folderId, String url) async {
    try {
      await DatabaseHelper.instance.addLinkToFolder(folderId, url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link saved to folder!')),
      );
    } catch (e) {
      print('Error saving link: ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving link: ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Saved Folders'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: const Icon(Icons.folder_open),
            title: Text(_folders[index]['name']),
            onTap: () {
              // Navigate to folder view
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FolderViewPage(
                    folderId: _folders[index]['id'],
                    folderName: _folders[index]['name'],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAddLinkDialog,
            tooltip: 'Add Link',
            child: const Icon(Icons.link),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _showAddFolderDialog,
            tooltip: 'Add Folder',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// New page to view links in a folder
class FolderViewPage extends StatefulWidget {
  final int folderId;
  final String folderName;

  const FolderViewPage({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderViewPage> createState() => _FolderViewPageState();
}

class _FolderViewPageState extends State<FolderViewPage> {
  List<Map<String, dynamic>> _links = [];

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  void _loadLinks() async {
    final data = await DatabaseHelper.instance.getLinksInFolder(widget.folderId);
    setState(() {
      _links = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        backgroundColor: Colors.deepPurple,
      ),
      body: _links.isEmpty
          ? const Center(
              child: Text(
                'No links saved in this folder yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _links.length,
              itemBuilder: (context, index) {
                final link = _links[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(
                      link['url'] ?? 'No URL',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Saved: ',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      // You can add functionality to open the link here
                      print('Tapped on link: ');
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteLink(link['id']);
                        _loadLinks(); // Refresh the list
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
