import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/theme_notifier.dart';
import '../../../../core/utils/snackbar_utils.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeNotifierProvider);
    final supabase = Supabase.instance.client;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profil Başlığı
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [Colors.grey[900]!, Colors.grey[800]!]
                      : [Colors.orange[400]!, Colors.orange[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.r),
                    bottomRight: Radius.circular(30.r),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 50.r,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Kullanıcı Adı',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      supabase.auth.currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20.h),
              
              // Menü Kartları
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    _buildMenuCard(
                      context,
                      icon: FontAwesomeIcons.utensils,
                      title: 'Restoran Yönetimi',
                      subtitle: 'Restoranınızı yönetin veya yeni restoran ekleyin',
                      onTap: () => _showRestaurantDialog(context),
                    ),
                    SizedBox(height: 15.h),
                    _buildMenuCard(
                      context,
                      icon: FontAwesomeIcons.gear,
                      title: 'Ayarlar',
                      subtitle: 'Uygulama ayarlarını özelleştirin',
                      onTap: () => context.push('/settings'),
                    ),
                    SizedBox(height: 15.h),
                    _buildMenuCard(
                      context,
                      icon: FontAwesomeIcons.circleInfo,
                      title: 'Hakkında',
                      subtitle: 'Uygulama bilgileri ve iletişim',
                      onTap: () {},
                    ),
                    SizedBox(height: 15.h),
                    _buildMenuCard(
                      context,
                      icon: FontAwesomeIcons.rightFromBracket,
                      title: 'Çıkış Yap',
                      subtitle: 'Hesabınızdan çıkış yapın',
                      onTap: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Çıkış Yap'),
                            content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('İptal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Çıkış Yap'),
                              ),
                            ],
                          ),
                        );

                        if (result == true && context.mounted) {
                          try {
                            await supabase.auth.signOut();
                            if (context.mounted) {
                              context.go('/auth');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Çıkış yapılırken bir hata oluştu'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(15.r),
        color: Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(15.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(15.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withAlpha(25)
                        : Theme.of(context).primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: FaIcon(
                    icon,
                    color: isDestructive
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                    size: 20.w,
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isDestructive ? Colors.red : null,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRestaurantDialog(BuildContext context) async {
    final supabase = Supabase.instance.client;
    
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        SnackbarUtils.showError(context, 'Oturum açmanız gerekiyor.');
        return;
      }

      final response = await supabase
          .from('restaurants')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        if (context.mounted) {
          context.push('/restaurant-dashboard');
        }
        return;
      }

      if (!context.mounted) return;
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restoran Oluştur'),
          content: const Text(
            'Henüz bir restoranınız bulunmuyor. '
            'Yeni bir restoran oluşturmak ister misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Oluştur'),
            ),
          ],
        ),
      );

      if (result == true && context.mounted) {
        context.push('/restaurant/create');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(
          context,
          'Restoran bilgileri kontrol edilirken bir hata oluştu.',
        );
      }
    }
  }
} 