import 'package:http/http.dart' as http;

class MySchemeApiExtractor {
  static const String bundleUrl = "https://cdn.myscheme.in/_next/static/chunks/pages/_app-6697e4fd0c08b018.js";
  String _status = "Ready to extract API key";

  // Regex to find X-Api-Key (Dart version)
  final RegExp xApiKeyRegex = RegExp(
    r'X-Api-Key.*[:=].*([A-Za-z0-9_\-]{20,})',
    caseSensitive: false,
  );

  Future<String> fetchBundle(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load bundle: ${response.statusCode}');
    }
  }

  String? extractXApiKey(String jsText) {
    final match = xApiKeyRegex.firstMatch(jsText);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  Future<String?> extractApiKey() async {

      _status = "Downloading bundle: $bundleUrl";
      


    try {
      final jsText = await fetchBundle(bundleUrl);

    
        _status = "Extracting API key from bundle...";
      

      final apiKey = extractXApiKey(jsText);

     
        if (apiKey != null) {
          _status = "✅ Found X-Api-Key!";
          return apiKey;
        } else {
        
          _status = "❌ X-Api-Key not found";
        return null;
        }
    } catch (e) {

        _status = "❌ Error: ${e.toString()}";
      return null;
    }

}
}