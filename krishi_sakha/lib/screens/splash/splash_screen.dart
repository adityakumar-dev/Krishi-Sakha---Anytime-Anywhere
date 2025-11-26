import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/utils/routes/routes.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:krishi_sakha/utils/ui/set_system_ui_overlay.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _opacityController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Opacity animation for logo
    _opacityController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _opacityController, curve: Curves.easeIn),
    );

    // Rotation animation for subtle spinning
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    // Start animations
    _scaleController.forward();
    _opacityController.forward();
    _rotateController.repeat();

    // Navigation after delay
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final provider = Provider.of<ProfileProvider>(context, listen: false);
      await  provider.initProfile();
        if(provider.userProfile != null) {
          context.go(AppRoutes.home);}
          else{
          context.go(AppRoutes.profileOnboard);
          }
      } else {
        context.go(AppRoutes.onboarding);
      }
    }
  }

  @override
/*************  ✨ Windsurf Command ⭐  *************/
/// Releases the resources used by the object.
///
/// This method is called when this object is no longer needed.
///
/// It is a good practice to call this method when this object is
/// no longer needed. This can help prevent memory leaks.
///
/// This method is automatically called when the widget is removed from
/// the widget tree. So, you don't need to call this method when the
/*******  c7f4b4eb-caad-4e3d-bfc0-3cfc2c65983d  *******/
  void dispose() {
    _scaleController.dispose();
    _opacityController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setSystemUIOverlayStyle();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated rotating circle background
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value * 6.28, // 2π radians
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Animated logo with scale and opacity
            AnimatedBuilder(
              animation: Listenable.merge(
                [_scaleAnimation, _opacityAnimation],
              ),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(
                              0.3 * _opacityAnimation.value,
                            ),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/krishi_logo.png',
                        height: 200,
                        width: 200,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}