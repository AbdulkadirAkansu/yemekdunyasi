import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yemekdunyasi/core/providers/theme_notifier.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSettingsView extends ConsumerWidget {
  const ProfileSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // Hesap Ayarları
            _buildSection(
              title: 'Hesap',
              children: [
                _buildSettingTile(
                  context,
                  icon: FontAwesomeIcons.user,
                  title: 'Profil Bilgileri',
                  subtitle: 'Kişisel bilgilerinizi düzenleyin',
                  onTap: () => context.push('/profile/edit'),
                ),
                _buildSettingTile(
                  context,
                  icon: FontAwesomeIcons.utensils,
                  title: 'Restoran Yönetimi',
                  subtitle: 'Restoranınızı yönetin veya yeni restoran ekleyin',
                  onTap: () => context.push('/restaurant-dashboard'),
                ),
                _buildSettingTile(
                  context,
                  icon: FontAwesomeIcons.locationDot,
                  title: 'Adres Yönetimi',
                  subtitle: 'Kayıtlı adreslerinizi düzenleyin',
                  onTap: () => context.push('/address/list'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Uygulama Ayarları
            _buildSection(
              title: 'Uygulama',
              children: [
                _buildSettingTile(
                  context,
                  icon: isDark ? FontAwesomeIcons.moon : FontAwesomeIcons.sun,
                  title: 'Tema',
                  subtitle: isDark ? 'Koyu tema aktif' : 'Açık tema aktif',
                  onTap: () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
                ),
                _buildSettingTile(
                  context,
                  icon: FontAwesomeIcons.bell,
                  title: 'Bildirimler',
                  subtitle: 'Bildirim ayarlarını düzenleyin',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Diğer
            _buildSection(
              title: 'Diğer',
              children: [
                _buildSettingTile(
                  context,
                  icon: FontAwesomeIcons.circleInfo,
                  title: 'Hakkında',
                  subtitle: 'Uygulama bilgileri',
                  onTap: () {},
                ),
                _buildSettingTile(
                  context,
                  icon: FontAwesomeIcons.rightFromBracket,
                  title: 'Çıkış Yap',
                  subtitle: 'Hesabınızdan çıkış yapın',
                  onTap: () => _handleSignOut(context),
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Theme.of(context).primaryColor;
    
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: FaIcon(
          icon,
          color: color,
          size: 20.w,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go('/auth');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılırken hata: $e')),
        );
      }
    }
  }
} 