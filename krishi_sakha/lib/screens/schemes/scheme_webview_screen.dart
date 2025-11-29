import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemeWebViewScreen extends StatefulWidget {
  final String slug;
  final String schemeName;

  const SchemeWebViewScreen({
    super.key,
    required this.slug,
    required this.schemeName,
  });

  @override
  State<SchemeWebViewScreen> createState() => _SchemeWebViewScreenState();
}

class _SchemeWebViewScreenState extends State<SchemeWebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  int _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  String get _schemeUrl => 'https://www.myscheme.gov.in/schemes/${widget.slug}';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (url) async {
            setState(() {
              _isLoading = false;
            });
            _updateNavigationState();
          },
          onProgress: (progress) {
            setState(() {
              _progress = progress;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
            });
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_schemeUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      appBar: AppBar(
        backgroundColor: AppColors.haraColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.schemeName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'myscheme.gov.in',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          // Refresh button
          IconButton(
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          // Open in browser
          IconButton(
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.haraColor),
              minHeight: 3,
            ),

          // WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
      // Bottom navigation bar for webview controls
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Back
              IconButton(
                onPressed: _canGoBack ? _goBack : null,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: _canGoBack ? AppColors.haraColor : Colors.grey.shade400,
                ),
              ),
              // Forward
              IconButton(
                onPressed: _canGoForward ? _goForward : null,
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: _canGoForward ? AppColors.haraColor : Colors.grey.shade400,
                ),
              ),
              // Home (go to scheme page)
              IconButton(
                onPressed: _goHome,
                icon: Icon(
                  Icons.home_rounded,
                  color: AppColors.haraColor,
                ),
              ),
              // Share
              IconButton(
                onPressed: _shareUrl,
                icon: Icon(
                  Icons.share_rounded,
                  color: AppColors.haraColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateNavigationState() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      _updateNavigationState();
    }
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
      _updateNavigationState();
    }
  }

  void _goHome() {
    _controller.loadRequest(Uri.parse(_schemeUrl));
  }

  Future<void> _openInBrowser() async {
    final currentUrl = await _controller.currentUrl();
    final url = currentUrl ?? _schemeUrl;
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  Future<void> _shareUrl() async {
    final currentUrl = await _controller.currentUrl();
    final url = currentUrl ?? _schemeUrl;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL copied: $url'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
