import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum NavigationTab {
  discover,
  favorites,
  cart,
  orders,
  profile;

  String get label {
    switch (this) {
      case NavigationTab.discover:
        return 'Keşfet';
      case NavigationTab.favorites:
        return 'Favorilerim';
      case NavigationTab.cart:
        return 'Sepetim';
      case NavigationTab.orders:
        return 'Siparişlerim';
      case NavigationTab.profile:
        return 'Profil';
    }
  }

  IconData get icon {
    switch (this) {
      case NavigationTab.discover:
        return Icons.explore_outlined;
      case NavigationTab.favorites:
        return Icons.favorite_outline;
      case NavigationTab.cart:
        return Icons.shopping_bag_outlined;
      case NavigationTab.orders:
        return Icons.receipt_outlined;
      case NavigationTab.profile:
        return Icons.person_outline;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case NavigationTab.discover:
        return Icons.explore;
      case NavigationTab.favorites:
        return Icons.favorite;
      case NavigationTab.cart:
        return Icons.shopping_bag;
      case NavigationTab.orders:
        return Icons.receipt;
      case NavigationTab.profile:
        return Icons.person;
    }
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      backgroundColor: colorScheme.surface,
      elevation: 3,
      height: 65.h,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: NavigationTab.values.map((tab) {
        final isSelected = selectedIndex == tab.index;
        return NavigationDestination(
          icon: Icon(
            tab.icon,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ).animate(target: isSelected ? 1 : 0).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.1, 1.1),
          ),
          selectedIcon: Icon(
            tab.selectedIcon,
            color: colorScheme.primary,
          ).animate(target: isSelected ? 1 : 0).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.1, 1.1),
          ).then().shake(
            duration: const Duration(milliseconds: 200),
          ),
          label: tab.label,
        );
      }).toList(),
    );
  }
} 