import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yemekdunyasi/features/splash/presentation/views/splash_view.dart';
import 'package:yemekdunyasi/features/auth/presentation/views/login_view.dart';
import 'package:yemekdunyasi/features/auth/presentation/views/register_view.dart';
import 'package:yemekdunyasi/features/home/presentation/views/home_view.dart';
import 'package:yemekdunyasi/features/auth/presentation/views/email_verification_view.dart';
import 'package:yemekdunyasi/features/restaurant/presentation/views/restaurant_management_view.dart';
import 'package:yemekdunyasi/features/profile/presentation/views/profile_settings_view.dart';
import 'package:yemekdunyasi/features/home/presentation/views/address_selection_view.dart';
import 'package:yemekdunyasi/features/auth/data/repositories/auth_repository.dart';
import 'package:yemekdunyasi/features/address/presentation/views/address_list_view.dart';
import 'package:yemekdunyasi/features/address/presentation/views/add_address_view.dart';
import 'package:yemekdunyasi/features/auth/presentation/views/email_confirmation_view.dart';
import 'package:yemekdunyasi/features/restaurant/presentation/views/restaurant_detail_view.dart';
import 'package:yemekdunyasi/features/restaurant/presentation/views/restaurant_dashboard_view.dart';
import '../../features/address/domain/entities/address.dart';

final _authRepository = AuthRepository();

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterView(),
      ),
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeView(),
            routes: [
              GoRoute(
                path: 'profile/settings',
                name: 'profile-settings',
                builder: (context, state) => const ProfileSettingsView(),
              ),
              GoRoute(
                path: 'address-selection',
                name: 'address-selection',
                builder: (context, state) => const AddressSelectionView(),
              ),
              GoRoute(
                path: 'address/list',
                name: 'address-list',
                builder: (context, state) => const AddressListView(),
              ),
              GoRoute(
                path: 'address/add',
                name: 'address-add',
                builder: (context, state) => const AddAddressView(),
              ),
              GoRoute(
                path: 'address/edit',
                name: 'address-edit',
                builder: (context, state) => AddAddressView(
                  initialAddress: state.extra as Address,
                ),
              ),
              GoRoute(
                path: 'restaurant/:id',
                name: 'restaurant-detail',
                builder: (context, state) {
                  final restaurant = state.extra as Map<String, dynamic>;
                  return RestaurantDetailView(restaurant: restaurant);
                },
              ),
              GoRoute(
                path: 'restaurant/dashboard',
                name: 'restaurant-dashboard',
                builder: (context, state) => const RestaurantDashboardView(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/email-verification',
        name: 'email-verification',
        builder: (context, state) {
          final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
          return EmailVerificationView(
            email: extra['email'] as String,
            password: extra['password'] as String,
            name: extra['name'] as String,
          );
        },
      ),
      GoRoute(
        path: '/restaurant-management',
        name: 'restaurant-management',
        builder: (context, state) => const RestaurantManagementView(),
      ),
      GoRoute(
        path: '/email-confirmation',
        name: 'email-confirmation',
        builder: (context, state) {
          final email = state.extra as String;
          return EmailConfirmationView(email: email);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Sayfa bulunamadı: ${state.uri.path}'),
      ),
    ),
    redirect: (context, state) async {
      final isLoggedIn = _authRepository.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/auth' || 
                         state.matchedLocation == '/register' ||
                         state.matchedLocation == '/email-confirmation' ||
                         state.matchedLocation == '/email-verification';
      final isSplash = state.matchedLocation == '/';

      // Splash ekranındaysa ve giriş yapmışsa home'a yönlendir
      if (isSplash && isLoggedIn) {
        return '/home';
      }

      // Splash ekranındaysa ve giriş yapmamışsa auth'a yönlendir
      if (isSplash && !isLoggedIn) {
        return '/auth';
      }

      // Giriş yapmamış kullanıcı korumalı sayfalara erişmeye çalışırsa
      if (!isLoggedIn && !isAuthRoute && !isSplash) {
        return '/auth';
      }

      // Giriş yapmış kullanıcı auth sayfalarına gitmeye çalışırsa
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
  );
} 