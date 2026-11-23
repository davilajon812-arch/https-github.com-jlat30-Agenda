import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../features/appointments/presentation/appointment_detail_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/billing/presentation/billing_screen.dart';
import '../../features/business/presentation/business_manage_screen.dart';
import '../../features/business/presentation/public_link_screen.dart';
import '../../features/client_booking/presentation/client_booking_screen.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/services/presentation/services_screen.dart';
import '../../features/staff/presentation/staff_schedule_screen.dart';
import '../../features/staff/presentation/staff_screen.dart';
import '../../l10n/app_localizations.dart';
import '../app_gate.dart';
import 'router_refresh.dart';

/// Rutas públicas (no requieren sesión).
const _publicRoutes = {'/login', '/register', '/forgot-password', '/book'};

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(supabaseClientProvider).auth;
  final refreshListenable = GoRouterRefreshStream(auth.onAuthStateChange);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final session = auth.currentSession;
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      if (session == null) {
        return isPublic ? null : '/login';
      }
      if (isPublic) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppGate()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/book',
        builder: (context, state) => const ClientBookingScreen(),
      ),
      GoRoute(
        path: '/appointments/:id',
        builder: (context, state) => AppointmentDetailScreen(
          appointmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (context, state) => ClientDetailScreen(
          clientId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/services',
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        path: '/business',
        builder: (context, state) => const BusinessManageScreen(),
      ),
      GoRoute(
        path: '/business/public-link',
        builder: (context, state) => const PublicLinkScreen(),
      ),
      GoRoute(path: '/staff', builder: (context, state) => const StaffScreen()),
      GoRoute(
        path: '/staff/:id/schedule',
        builder: (context, state) => StaffScheduleScreen(
          staffId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/plan',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: Text(AppLocalizations.of(context).billingTitle)),
          body: const BillingScreen(),
        ),
      ),
    ],
  );
});
