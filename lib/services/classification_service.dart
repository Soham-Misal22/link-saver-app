
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> classifyFolder(String folderName, List<String> captions) async {
    try {
      final response = await _supabase.functions.invoke(
        'classify-folder',
        body: {
          'folderName': folderName,
          'captions': captions,
        },
      );

      final data = response.data;
      if (data != null && data['category'] != null) {
        return data['category'] as String;
      }
      return null;
    } catch (e) {
      print('Error classifying folder: $e');
      return null;
    }
  }
}
