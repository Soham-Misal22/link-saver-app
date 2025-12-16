import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class LinkMetadata {
  final String title;
  final String? description;
  final String? image;
  final String? siteName;
  final List<String> keywords;
  final String? section;

  LinkMetadata({
    required this.title,
    this.description,
    this.image,
    this.siteName,
    this.keywords = const [],
    this.section,
  });
}

class MetadataService {
  static Future<LinkMetadata> fetchMetadata(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load page');
      }

      final document = html_parser.parse(response.body);
      
      // Title
      String title = document.head?.querySelector('title')?.text ?? '';
      if (title.isEmpty) {
        title = document.querySelector('meta[property="og:title"]')?.attributes['content'] ?? '';
      }
      
      // Description
      String? description = document.querySelector('meta[property="og:description"]')?.attributes['content'];
      if (description == null || description.isEmpty) {
        description = document.querySelector('meta[name="description"]')?.attributes['content'];
      }

      // Image
      String? image = document.querySelector('meta[property="og:image"]')?.attributes['content'];

      // Site Name
      String? siteName = document.querySelector('meta[property="og:site_name"]')?.attributes['content'];
      if (siteName == null || siteName.isEmpty) {
         // Fallback to domain name if site_name is missing
         siteName = uri.host.replaceFirst('www.', '');
      }

      // Keywords
      List<String> keywords = [];
      String? keywordsStr = document.querySelector('meta[name="keywords"]')?.attributes['content'];
      if (keywordsStr != null && keywordsStr.isNotEmpty) {
        keywords = keywordsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }

      // Section / Category
      String? section = document.querySelector('meta[property="article:section"]')?.attributes['content'];
      if (section == null || section.isEmpty) {
        // Try product category
        section = document.querySelector('meta[property="product:category"]')?.attributes['content'];
      }

      return LinkMetadata(
        title: title.trim(),
        description: description?.trim(),
        image: image,
        siteName: siteName?.trim(),
        keywords: keywords,
        section: section?.trim(),
      );
    } catch (e) {
      // Return basic metadata if fetching fails
      final uri = Uri.tryParse(url);
      return LinkMetadata(
        title: uri?.host ?? 'Link',
        siteName: uri?.host,
      );
    }
  }
}
