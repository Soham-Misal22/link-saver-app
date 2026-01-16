import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../services/metadata_service.dart';

class FolderSuggestion {
  final String name;
  final bool isExisting;
  final String reason; // e.g., "Matched 'YouTube'", "New from site name"

  FolderSuggestion({
    required this.name,
    required this.isExisting,
    required this.reason,
  });
}



class SuggestionService {
  
  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('debug_device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('debug_device_id', deviceId);
    }
    return deviceId;
  }

  static Future<void> logDebugEvent(String stage, Map<String, dynamic> payload) async {
    try {
      final deviceId = await _getDeviceId();
      await Supabase.instance.client.from('debug_events').insert({
        'device_id': deviceId,
        'stage': stage,
        'payload': payload,
      });
    } catch (e) {
      print('Failed to log debug event: $e');
    }
  }

  static Future<List<String>> fetchAiSuggestions(String caption) async {
      if (caption.trim().isEmpty) return [];

      print("Calling suggest-folders with caption: $caption");
      
      await logDebugEvent('flutter_calling_backend', {'caption': caption});

      try {
        final deviceId = await _getDeviceId();
        final response = await Supabase.instance.client.functions.invoke('suggest-folders', body: {
            'caption': caption,
            'device_id': deviceId,
        });
        final result = response.data;
        print("suggest-folders returned: $result");
        
        await logDebugEvent('flutter_received_response', {'response': result});

        final data = result;
        
        if (data != null) {
          if (data['error'] != null) {
             print('LinkSaver: Backend returned error: ${data['error']}');
          }
          if (data['suggestions'] != null) {
            return List<String>.from(data['suggestions']);
          }
        }
        return [];
      } catch (e) {
        print("suggest-folders error: $e");
        await logDebugEvent('flutter_error', {'error': e.toString()});
        return [];
      }
  }
  
  // 1. Common Presets "Starter Kit" for New Users
  static final Map<String, List<String>> _commonPresets = {
    'Technology': ['software', 'programming', 'code', 'developer', 'ai', 'tech', 'gadget', 'python', 'javascript', 'flutter', 'linux', 'app', 'github'],
    'Music': ['song', 'lyrics', 'album', 'concert', 'band', 'spotify', 'guitar', 'piano', 'track', 'playlist', 'soundcloud'],
    'Travel': ['trip', 'hotel', 'flight', 'vacation', 'tour', 'destination', 'resort', 'beach', 'adventure', 'booking', 'airbnb'],
    'Finance': ['stock', 'market', 'crypto', 'bitcoin', 'investment', 'money', 'finance', 'trading', 'bank', 'economy', 'budget'],
    'News': ['breaking', 'news', 'report', 'update', 'politics', 'world', 'daily', 'headline', 'article', 'cnn', 'bbc'],
    'Education': ['learn', 'tutorial', 'course', 'study', 'university', 'lesson', 'class', 'school', 'exam', 'education'],
    'Fitness': ['workout', 'gym', 'yoga', 'fitness', 'exercise', 'health', 'muscle', 'diet', 'running', 'sport'],
    'Shopping': ['buy', 'shop', 'store', 'price', 'deal', 'discount', 'sale', 'amazon', 'ebay', 'product'],
    'Entertainment': ['movie', 'film', 'series', 'netflix', 'drama', 'cinema', 'actor', 'game', 'gaming', 'twitch'],
    'Food': ['recipe', 'cook', 'baking', 'meal', 'dish', 'food', 'restaurant', 'taste', 'snack', 'cuisine', 'dinner'],
  };

  // 2. Stop Words (Noise Filter)
  static const Set<String> _stopWords = {
    'the', 'is', 'at', 'which', 'on', 'and', 'a', 'an', 'in', 'to', 'for', 'of', 'with', 'by', 'from', 'up', 'about', 'into', 'over', 'after',
    'how', 'what', 'why', 'where', 'when', 'who', 'best', 'top', 'vs', 'guide', 'tutorial', 'review', '2024', '2025', 'new', 'free'
  };

  static List<FolderSuggestion> suggestFolders(
    LinkMetadata meta,
    List<Map<String, dynamic>> existingFolders,
    List<Map<String, dynamic>> savedLinksHistory,
  ) {
    final suggestions = <FolderSuggestion>[];
    
    // Normalize Input
    final inputTokens = _tokenize('${meta.title} ${meta.description ?? ''} ${meta.keywords.join(' ')}');
    final siteNameLower = (meta.siteName ?? '').toLowerCase();

    // --- STEP 1: HISTORY MATCHING (Adaptive) ---
    // Build "Folder Profiles" from history
    if (savedLinksHistory.isNotEmpty) {
      final folderScores = <int, double>{}; // folderId -> score

      // Pre-process history into profiles
      // Map<int, List<String>> folderWords = {}; 
      // Instead of storing, we compute score on the fly for efficiency
      
      for (final link in savedLinksHistory) {
        final fId = link['folder_id'];
        if (fId == null || fId is! int) continue;
        
        final linkTitle = (link['title'] ?? '').toString();
        // Check site name overlap from URL if available, else skip
        // We use title for now
        
        double linkScore = 0;
        final linkTokens = _tokenize(linkTitle);
        
        for (final token in inputTokens) {
          if (linkTokens.contains(token)) {
             linkScore += 1.0;
          }
        }
        
        // Boost if site name matches history (strong signal)
        // e.g. User put a YouTube link in this folder before
        final linkUrl = (link['url'] ?? '').toString().toLowerCase();
        if (siteNameLower.isNotEmpty && linkUrl.contains(siteNameLower)) {
           linkScore += 3.0;
        }

        if (linkScore > 0) {
          folderScores[fId] = (folderScores[fId] ?? 0) + linkScore;
        }
      }

      // Finds best History matches
      final sortedHistory = folderScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)); // descending

      for (final entry in sortedHistory.take(3)) {
        final folder = existingFolders.firstWhere((f) => f['id'] == entry.key, orElse: () => {});
        if (folder.isNotEmpty) {
           suggestions.add(FolderSuggestion(
             name: folder['name'],
             isExisting: true,
             reason: 'You save similar links here',
           ));
        }
      }
    }

    // --- STEP 2: PRESET MATCHING (Cold Start "Starter Kit") ---
    // Match against Global Presets
    final presetScores = <String, int>{};
    _commonPresets.forEach((category, keywords) {
       int score = 0;
       for (final keyword in keywords) {
         if (inputTokens.contains(keyword)) score++;
       }
       if (score > 0) presetScores[category] = score;
    });

    final sortedPresets = presetScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    for (final entry in sortedPresets.take(2)) {
      final name = entry.key;
      // Don't duplicate if already suggested via history
      if (suggestions.any((s) => s.name == name)) continue;

      // Check if user already has this folder
      final existing = existingFolders.firstWhere((f) => f['name'] == name, orElse: () => {});
      
      suggestions.add(FolderSuggestion(
        name: name,
        isExisting: existing.isNotEmpty,
        reason: existing.isNotEmpty ? 'Matches content' : 'Popular category',
      ));
    }

    // --- STEP 3: METADATA FALLBACK (Smart Defaults) ---
    // Trust explicit tags from the site
    if (meta.section != null && meta.section!.isNotEmpty) {
      final sectionName = meta.section!;
       if (!suggestions.any((s) => s.name.toLowerCase() == sectionName.toLowerCase())) {
          final existing = existingFolders.firstWhere(
             (f) => (f['name'] as String).toLowerCase() == sectionName.toLowerCase(), 
             orElse: () => {}
          );
          suggestions.add(FolderSuggestion(
            name: existing.isNotEmpty ? existing['name'] : sectionName,
            isExisting: existing.isNotEmpty,
            reason: 'From website category',
          ));
       }
    }

    // Site Name fallback
    if (siteNameLower.isNotEmpty && suggestions.length < 3) {
       // Only if we haven't found good matches
       final name = meta.siteName!;
       if (!suggestions.any((s) => s.name.toLowerCase() == siteNameLower)) {
          final existing = existingFolders.firstWhere(
             (f) => (f['name'] as String).toLowerCase() == siteNameLower, 
             orElse: () => {}
          );
          suggestions.add(FolderSuggestion(
            name: existing.isNotEmpty ? existing['name'] : name,
            isExisting: existing.isNotEmpty,
            reason: 'From site name',
          ));
       }
    }

    // Deduplicate and limit
    final unique = <FolderSuggestion>[];
    final seen = <String>{};
    for (final s in suggestions) {
      if (!seen.contains(s.name)) {
        unique.add(s);
        seen.add(s.name);
      }
      if (unique.length >= 3) break;
    }
    
    return unique;
  }

  // Helper: Tokenize text into clean words
  static Set<String> _tokenize(String text) {
    return text.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '') // remove punctuation
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 2 && !_stopWords.contains(w))
      .toSet();
  }
}
