// lib/share_receiver_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class ShareReceiverService {
  static final ShareReceiverService _instance = ShareReceiverService._internal();
  factory ShareReceiverService() => _instance;
  ShareReceiverService._internal();

  static const MethodChannel _channel = MethodChannel('share_receiver');
  String? _sharedUrl;
  bool _isInitialized = false;
  OverlayEntry? _overlayEntry;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Check for shared text when app starts
    _checkForSharedText();
  }

  Future<void> _checkForSharedText() async {
    try {
      final String? sharedText = await _channel.invokeMethod('getSharedText');
      if (sharedText != null && sharedText.isNotEmpty) {
        _sharedUrl = sharedText;
        _showShareDialog();
      }
    } catch (e) {
      print('Error getting shared text: $e');
    }
  }

  void _showShareDialog() {
    if (_sharedUrl == null) return;
    _showOverlayDialog();
  }

  void _showOverlayDialog() {
    // Get the current overlay
    final overlay = WidgetsBinding.instance.overlay;
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ShareDialog(
              sharedUrl: _sharedUrl!,
              onClose: () {
                _overlayEntry?.remove();
                _overlayEntry = null;
                _sharedUrl = null;
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class ShareDialog extends StatefulWidget {
  final String sharedUrl;
  final VoidCallback onClose;

  const ShareDialog({
    super.key,
    required this.sharedUrl,
    required this.onClose,
  });

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  List<Map<String, dynamic>> _folders = [];
  bool _isLoading = true;
  final supabase = Supabase.instance.client;

  Future<String?> _getMappedUserId() async {
    final clerkUser = ClerkAuth.of(context).user;
    if (clerkUser == null) return null;
    try {
      final result = await supabase
          .from('user_mapping')
          .select('supabase_user_id')
          .eq('clerk_user_id', clerkUser.id)
          .maybeSingle();
      final mapped = result != null ? result['supabase_user_id'] as String? : null;
      return mapped ?? clerkUser.id;
    } catch (_) {
      return clerkUser.id;
    }
  }

  Future<List<String>> _getUserIdCandidates() async {
    final clerkUser = ClerkAuth.of(context).user;
    if (clerkUser == null) return [];
    final mapped = await _getMappedUserId();
    final ids = <String>{};
    if (mapped != null) ids.add(mapped);
    ids.add(clerkUser.id);
    return ids.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final idCandidates = await _getUserIdCandidates();
      if (idCandidates.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await supabase
          .from('folders')
          .select()
          .inFilter('user_id', idCandidates);
      setState(() {
        final list = List<Map<String, dynamic>>.from(data);
        list.sort((a, b) {
          final at = _parseCreatedAtFlexible(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = _parseCreatedAtFlexible(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
        _folders = list;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading folders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLinkToFolder(int folderId) async {
    try {
      final mappedUserId = await _getMappedUserId();
      if (mappedUserId == null) return;

      final formattedUrl = _ensureHttpScheme(widget.sharedUrl);
      final metadata = await _fetchUrlMetadata(formattedUrl);

      await supabase.from('saved_links').insert({
        'folder_id': folderId,
        'user_id': mappedUserId,
        'url': formattedUrl,
        'title': metadata['title'],
        'thumbnail_url': metadata['favicon'],
        'created_at': DateTime.now().toIso8601String(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link saved successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Close dialog
      widget.onClose();
    } catch (e) {
      print('Error saving link: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving link: $e')),
      );
    }
  }

  String _ensureHttpScheme(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }

  Future<Map<String, String?>> _fetchUrlMetadata(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final document = html_parser.parse(response.body);
        final titleTag = document.querySelector('title');
        final ogTitle = document
            .querySelector('meta[property="og:title"]')
            ?.attributes['content'];
        final metaTitle = document
            .querySelector('meta[name="title"]')
            ?.attributes['content'];
        final resolvedTitle =
        (ogTitle ?? metaTitle ?? titleTag?.text ?? '').trim();

        String? favicon = document
            .querySelector('link[rel~="shortcut"][rel~="icon"]')
            ?.attributes['href'] ??
            document.querySelector('link[rel~="icon"]')?.attributes['href'] ??
            '/favicon.ico';

        favicon = _resolveUrl(url, favicon);

        return {
          'title': resolvedTitle.isEmpty ? null : resolvedTitle,
          'favicon': favicon,
        };
      }
    } catch (_) {}
    final uri = Uri.tryParse(url);
    final hostTitle = uri?.host ?? url;
    final favicon = _resolveUrl(url, '/favicon.ico');
    return {'title': hostTitle, 'favicon': favicon};
  }

  DateTime? _parseCreatedAtFlexible(dynamic createdAt) {
    try {
      if (createdAt == null) return null;
      if (createdAt is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAt).toLocal();
      }
      final s = createdAt.toString();
      if (RegExp(r'^\d{13}$').hasMatch(s.trim())) {
        final ms = int.tryParse(s.trim());
        if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      }
      String t = s.contains('T') ? s : s.replaceFirst(' ', 'T');
      final frac = RegExp(r'(\.\d{1,})').firstMatch(t)?.group(1);
      if (frac != null && frac.length > 7) {
        t = t.replaceFirst(frac, frac.substring(0, 7));
      }
      final hasZone = RegExp(r'[zZ]|[\+\-]\d{2}:?\d{2}').hasMatch(t);
      if (!hasZone) {
        return DateTime.parse(t);
      } else {
        final dt = DateTime.parse(t);
        return dt.isUtc ? dt.toLocal() : dt;
      }
    } catch (_) {}
    return null;
  }

  String _resolveUrl(String baseUrl, String? href) {
    if (href == null || href.isEmpty) return baseUrl;
    try {
      final base = Uri.parse(baseUrl);
      final resolved = Uri.parse(href);
      final uri = resolved.hasScheme ? resolved : base.resolveUri(resolved);
      return uri.toString();
    } catch (_) {
      return href;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Color(0xFF6E8EF5)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Save Link',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.sharedUrl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose folder:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_folders.isEmpty)
            const Text(
              'No folders found. Create one in the app first.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  final folder = _folders[index];
                  return ListTile(
                    leading: const Icon(Icons.folder, color: Color(0xFF6E8EF5)),
                    title: Text(folder['name']),
                    onTap: () => _saveLinkToFolder(folder['id']),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}