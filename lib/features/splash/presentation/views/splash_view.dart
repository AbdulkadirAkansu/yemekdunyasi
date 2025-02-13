import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yemekdunyasi/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _loadingController;
  late Animation<double> _iconAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startNavigation();
  }

  void _setupAnimations() {
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _iconAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.elasticOut,
      ),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeInOut,
      ),
    );

    _iconController.forward();
  }

  Future<void> _startNavigation() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    // Mevcut oturumu kontrol et
    final session = Supabase.instance.client.auth.currentSession;
    print('🔄 Splash navigation check:');
    print('- Session exists: ${session != null}');
    
    if (session != null) {
      if (!mounted) return;
      print('➡️ Navigating to /main from splash');
      context.go('/main');  // /home yerine /main kullanıyoruz
    } else {
      if (!mounted) return;
      print('➡️ Navigating to /auth from splash');
      context.go('/auth');
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasyonlu İkon
            ScaleTransition(
              scale: _iconAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 120,
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  Icon(
                    Icons.restaurant,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Uygulama Adı
            Text(
              'Yemek Dünyası',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Slogan
            Text(
              'Lezzetin Yeni Adresi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading İndikatör
            RotationTransition(
              turns: _loadingAnimation,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 