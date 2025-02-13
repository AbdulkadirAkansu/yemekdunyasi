import 'package:flutter/material.dart';
import 'package:yemekdunyasi/core/theme/app_theme.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Restoran veya yemek ara...',
          border: InputBorder.none,
          icon: Icon(
            Icons.search,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
} 