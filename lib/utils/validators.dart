/// Input validation utilities for the Link Saver app.
/// Provides validation for URLs, folder names, and other user inputs.
class Validators {
  /// Validates if a string is a valid HTTP/HTTPS URL.
  static bool isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Validates folder name and returns error message if invalid.
  /// Returns null if valid.
  static String? validateFolderName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Folder name cannot be empty';
    }

    final trimmedName = name.trim();

    if (trimmedName.length > 50) {
      return 'Folder name too long (maximum 50 characters)';
    }

    if (trimmedName.length < 2) {
      return 'Folder name too short (minimum 2 characters)';
    }

    // Check for invalid characters
    final invalidCharsRegex = RegExp(r'[<>:"/\\|?*]');
    if (invalidCharsRegex.hasMatch(trimmedName)) {
      return 'Folder name contains invalid characters';
    }

    return null; // Valid
  }

  /// Sanitizes user input to prevent injection attacks.
  static String sanitizeInput(String? input) {
    if (input == null) return '';
    
    return input
        .trim()
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s\-_.,!?@#()]'), ''); // Keep safe chars
  }

  /// Validates email format.
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return false;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Validates link title/caption.
  static String? validateLinkTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return null; // Optional field
    }

    if (title.length > 200) {
      return 'Title too long (maximum 200 characters)';
    }

    return null; // Valid
  }

  /// Ensures URL has a valid scheme, adds https if missing.
  static String ensureHttpScheme(String url) {
    if (url.trim().isEmpty) return url;
    
    final trimmed = url.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }
}
