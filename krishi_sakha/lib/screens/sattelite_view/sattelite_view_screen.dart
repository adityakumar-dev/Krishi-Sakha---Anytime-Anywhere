import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:krishi_sakha/services/app_logger.dart';
import 'package:krishi_sakha/services/weather_service.dart';

class SatteliteViewScreen extends StatefulWidget {
  const SatteliteViewScreen({
    super.key,
  });

  @override
  State<SatteliteViewScreen> createState() => _SatteliteViewScreenState();
}

class _SatteliteViewScreenState extends State<SatteliteViewScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _error;
  String _currentUrl = '';
  late WeatherService _weatherService;
  double _latitude = 28.3113; // Default: Dehradun
  double _longitude = 81.4999; // Default: Dehradun

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController(); // Initialize with empty controller
    _weatherService = WeatherService();
    _initializeLocation();
  }

  /// Get current user location and initialize WebView
  Future<void> _initializeLocation() async {
    try {
      AppLogger.info('📍 Fetching current location...');
      final position = await _weatherService.getCurrentLocation();
      
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        AppLogger.info(
          '✅ Location fetched: $_latitude, $_longitude',
        );
      } else {
        AppLogger.warning('⚠️ Could not get location, using default');
      }
    } catch (e) {
      AppLogger.error('❌ Error getting location: $e');
    } finally {
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    // Use desktop Chrome user agent to avoid mobile detection and blocking
    const userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36 Edg/121.0.0.0';

    // Minimal browser headers - only essential ones
    final requestHeaders = {
      'User-Agent': userAgent,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
    };

    AppLogger.info(
      '🌐 Initializing WebView with coordinates: $_latitude, $_longitude',
    );
    AppLogger.debug('📋 Desktop User-Agent: Chrome/Edge on Windows');

    // Build Zoom.earth URL with coordinates
    _currentUrl =
        'https://zoom.earth/maps/humidity/#view=$_latitude,$_longitude,7z/model=icon';

    AppLogger.info('🔗 Loading URL: $_currentUrl');

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Use desktop user agent
      ..setUserAgent(userAgent)
      // Add JavaScript channel to log from web console
      ..addJavaScriptChannel(
        'FlutterLogger',
        onMessageReceived: (JavaScriptMessage message) {
          AppLogger.info('💻 [WebView JS]: ${message.message}');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _currentUrl = url;
            setState(() => _isLoading = true);
            AppLogger.info('📍 Page started loading: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _error = null;
            });
            AppLogger.info('✅ Page finished loading: $url');
            // Inject logging script into page
            _injectLoggingScript();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
            AppLogger.error(
              '❌ WebView error: ${error.description}',
              error.description,
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            AppLogger.info('🔗 Navigation request: ${request.url}');
            // Allow ALL navigation requests for maximum flexibility
            return NavigationDecision.navigate;
          },
        ),
      )
      // Load initial URL with custom headers
      ..loadRequest(
        Uri.parse(_currentUrl),
        headers: requestHeaders,
      );

    AppLogger.info('✨ WebView initialization complete - Desktop Mode');
  }

  /// Inject logging script to track browser activities
  Future<void> _injectLoggingScript() async {
    const loggingScript = '''
    console.log('🎯 Weather Map Page Loaded Successfully');
    
    // Log all fetch requests
    const originalFetch = window.fetch;
    window.fetch = function(...args) {
      console.log('📡 Fetch request:', args[0]);
      return originalFetch.apply(this, args);
    };
    
    // Log all XHR requests
    const originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method, url, ...args) {
      console.log('📡 XHR request:', method, url);
      return originalOpen.apply(this, [method, url, ...args]);
    };
    
    // Log page errors
    window.addEventListener('error', function(e) {
      console.error('⚠️ Page error:', e.message);
    });
    
    console.log('✅ Logging script injected successfully');
    ''';

    try {
      await _webViewController.runJavaScript(loggingScript);
      AppLogger.debug('📝 Logging script injected into page');
    } catch (e) {
      AppLogger.warning('⚠️ Could not inject logging script: $e');
    }
  }

  /// Build space particles background for loading animation
  Widget _buildSpaceParticles() {
    return CustomPaint(
      painter: SpaceParticlesPainter(),
      size: Size.infinite,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor : _isLoading ?  const Color(0xFFF7F5E8) : Colors.transparent,
      // appBar: _isLoading ? null : AppBar(
      //   leading: IconButton(onPressed: ()=> context.pop(), icon: Icon(Icons.arrow_back_ios, color: Colors.white,)),
      //   backgroundColor: Colors.transparent,
      //   title: const Text(
      //     'Precipitation Map',
      //     style: TextStyle(
      //       color: AppColors.primaryWhite,
      //       fontSize: 20,
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      //   elevation: 0,
      //   actions: [
      //     IconButton(
      //       onPressed: _webViewController.reload,
      //       icon: const Icon(Icons.refresh),
      //       tooltip: 'Refresh',
      //     ),
      //   ],
      // ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _webViewController),

          // Loading Indicator with Space Particles
          if (_isLoading)
            Container(
              color: const Color(0xFFF7F5E8).withOpacity(0.95),
              child: Stack(
                children: [
                  // Space particles background
                  _buildSpaceParticles(),
                  
                  // Main content
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 3D Satellite Animation
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primaryGreen.withOpacity(0.2),
                                  AppColors.primaryGreen.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Lottie.asset(
                              'assets/lottie/sattelite.json',
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                              repeat: true,
                              animate: true,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Main loading text
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                AppColors.primaryGreen,
                                AppColors.primaryGreen.withOpacity(0.6),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Satellite Loading',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Loading description
                          Text(
                            'Syncing humidity data from space',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Loading progress bar
                          Container(
                            width: 240,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.grey[300],
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryGreen,
                                        AppColors.primaryGreen.withOpacity(0.4),
                                      ],
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      minHeight: 4,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Loading details
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.primaryGreen.withOpacity(0.05),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: AppColors.primaryGreen,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Coordinates: $_latitude, $_longitude',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_download,
                                      color: AppColors.primaryGreen,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Fetching humidity map...',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Error State
          if (_error != null && !_isLoading)
            Container(
              color: const Color(0xFFF7F5E8),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: const Color(0xFFF44336).withOpacity(0.8),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to Load Map',
                        style: TextStyle(
                          color: AppColors.primaryBlack,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ?? 'Unknown error occurred',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _error = null);
                          _initializeWebView();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.primaryBlack,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        
      ),
      floatingActionButton: _isLoading
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Exit button at top
                FloatingActionButton(
                  onPressed: () => context.pop(),
                  backgroundColor: AppColors.primaryGreen,
                  heroTag: 'exitBtn',
                  mini: true,
                  child: const Icon(Icons.exit_to_app, color: AppColors.primaryBlack),
                ),
                // Refresh button at bottom
                FloatingActionButton(
                  onPressed: _webViewController.reload,
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.8),
                  heroTag: 'refreshBtn',
                  mini: true,
                  child: const Icon(Icons.refresh, color: AppColors.primaryBlack),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
            );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Custom painter for drawing animated space particles
class SpaceParticlesPainter extends CustomPainter {
  late final List<Particle> particles;
  late final Paint paintParticle;
  
  SpaceParticlesPainter() {
    paintParticle = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Generate random particles
    particles = List.generate(
      50,
      (index) => Particle(
        x: (index * 7.3) % 100, // Distribute across screen
        y: (index * 11.5) % 100,
        size: (index % 3 + 1).toDouble(),
        opacity: 0.3 + (index % 7) / 10,
        speed: 0.1 + (index % 5) * 0.05,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw particles
    for (final particle in particles) {
      paintParticle.color = AppColors.primaryGreen.withOpacity(particle.opacity);
      
      // Animate particle position
      final animatedY = (particle.y + particle.speed * DateTime.now().millisecondsSinceEpoch / 100) % 100;
      
      final x = (particle.x / 100) * width;
      final y = (animatedY / 100) * height;

      // Draw glowing circle
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paintParticle,
      );

      // Draw glow effect
      paintParticle.color = AppColors.primaryGreen.withOpacity(particle.opacity * 0.5);
      canvas.drawCircle(
        Offset(x, y),
        particle.size * 2,
        paintParticle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Particle model for space background
class Particle {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double speed;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
  });
}