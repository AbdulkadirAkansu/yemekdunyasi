import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yemekdunyasi/core/theme/app_theme.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      'https://ui-avatars.com/api/?name=John+Doe&background=random',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? 'Kullanıcı',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            _buildListTile(
              icon: Icons.person_outline,
              title: 'Profil Bilgileri',
              onTap: () {},
            ),
            _buildListTile(
              icon: Icons.location_on_outlined,
              title: 'Adreslerim',
              onTap: () {},
            ),
            _buildListTile(
              icon: Icons.payment_outlined,
              title: 'Ödeme Yöntemlerim',
              onTap: () {},
            ),
            _buildListTile(
              icon: Icons.notifications_outlined,
              title: 'Bildirim Ayarları',
              onTap: () {},
            ),
            _buildListTile(
              icon: Icons.help_outline,
              title: 'Yardım',
              onTap: () {},
            ),
            _buildListTile(
              icon: Icons.logout,
              title: 'Çıkış Yap',
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  context.go('/auth');
                }
              },
              color: Colors.red,
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 