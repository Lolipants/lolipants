import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/router/role_routing.dart';

export 'package:lolipants/core/router/role_routing.dart'
    show homeForRole, postAuthLocation;
import 'package:lolipants/features/admin/screens/admin_complaints_screen.dart';
import 'package:lolipants/features/admin/screens/admin_news_screen.dart';
import 'package:lolipants/features/admin/screens/admin_cms_screen.dart';
import 'package:lolipants/features/admin/screens/admin_moderation_screen.dart';
import 'package:lolipants/features/admin/screens/admin_orders_screen.dart';
import 'package:lolipants/features/admin/screens/admin_payouts_screen.dart';
import 'package:lolipants/features/admin/screens/admin_stats_screen.dart';
import 'package:lolipants/features/admin/screens/admin_role_requests_screen.dart';
import 'package:lolipants/features/admin/screens/admin_users_screen.dart';
import 'package:lolipants/features/admin/shell/admin_shell.dart';
import 'package:lolipants/features/auth/models/user.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/delivery/screens/delivery_active_screen.dart';
import 'package:lolipants/features/delivery/screens/delivery_history_screen.dart';
import 'package:lolipants/features/delivery/screens/delivery_order_detail_screen.dart';
import 'package:lolipants/features/delivery/screens/delivery_queue_screen.dart';
import 'package:lolipants/features/delivery/shell/delivery_shell.dart';
import 'package:lolipants/features/auth/screens/forgot_password_screen.dart';
import 'package:lolipants/features/auth/screens/login_screen.dart';
import 'package:lolipants/features/auth/screens/otp_screen.dart';
import 'package:lolipants/features/auth/screens/signup_screen.dart';
import 'package:lolipants/features/browse/screens/browse_screen.dart';
import 'package:lolipants/features/browse/screens/category_detail_screen.dart';
import 'package:lolipants/features/browse/screens/garment_style_screen.dart';
import 'package:lolipants/features/browse/screens/mannequin_selector_screen.dart';
import 'package:lolipants/features/community/screens/news_article_detail_screen.dart';
import 'package:lolipants/features/community/screens/community_screen.dart';
import 'package:lolipants/features/community/screens/create_post_screen.dart';
import 'package:lolipants/features/community/screens/post_detail_screen.dart';
import 'package:lolipants/features/community/screens/designer_profile_screen.dart';
import 'package:lolipants/features/community/screens/designer_earnings_screen.dart';
import 'package:lolipants/features/community/models/post.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/home/models/home_flow_selection.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/editor/screens/editor_screen.dart';
import 'package:lolipants/features/home/screens/home_screen.dart';
import 'package:lolipants/features/onboarding/screens/onboarding_screen.dart';
import 'package:lolipants/features/orders/screens/delivery_details_screen.dart';
import 'package:lolipants/features/orders/screens/order_confirmation_screen.dart';
import 'package:lolipants/features/orders/screens/order_quote_review_screen.dart';
import 'package:lolipants/features/orders/screens/order_detail_screen.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/accessories/models/accessory.dart';
import 'package:lolipants/features/accessories/screens/accessory_detail_screen.dart';
import 'package:lolipants/features/orders/models/accessory_order_draft.dart';
import 'package:lolipants/features/orders/models/wedding_order_draft.dart';
import 'package:lolipants/features/orders/screens/order_accessory_quote_review_screen.dart';
import 'package:lolipants/features/orders/screens/order_accessory_summary_screen.dart';
import 'package:lolipants/features/orders/screens/order_summary_screen.dart';
import 'package:lolipants/features/orders/screens/order_wedding_quote_review_screen.dart';
import 'package:lolipants/features/orders/screens/order_wedding_summary_screen.dart';
import 'package:lolipants/features/wedding/models/wedding_flow_args.dart';
import 'package:lolipants/features/wedding/screens/wedding_dress_browse_screen.dart';
import 'package:lolipants/features/wedding/screens/wedding_dress_detail_screen.dart';
import 'package:lolipants/features/wedding/screens/wedding_fulfillment_screen.dart';
import 'package:lolipants/features/orders/screens/orders_screen.dart';
import 'package:lolipants/features/orders/screens/payment_screen.dart';
import 'package:lolipants/features/orders/screens/size_confirmation_screen.dart';
import 'package:lolipants/features/tailor/screens/tailor_order_detail_screen.dart';
import 'package:lolipants/features/tailor/shell/tailor_shell.dart';
import 'package:lolipants/features/tailor/screens/tailor_incoming_orders_screen.dart';
import 'package:lolipants/features/tailor/screens/tailor_pricing_screen.dart';
import 'package:lolipants/features/tailor/screens/tailor_active_orders_screen.dart';
import 'package:lolipants/features/tailor/screens/tailor_completed_orders_screen.dart';
import 'package:lolipants/features/orders/screens/quote_negotiation_detail_screen.dart';
import 'package:lolipants/features/tailor/screens/tailor_price_requests_screen.dart';
import 'package:lolipants/features/tailor/screens/tailor_quote_negotiation_detail_screen.dart';
import 'package:lolipants/features/profile/screens/edit_profile_screen.dart';
import 'package:lolipants/features/profile/screens/my_designs_screen.dart';
import 'package:lolipants/features/profile/screens/my_measurements_screen.dart';
import 'package:lolipants/features/profile/screens/my_price_negotiations_screen.dart';
import 'package:lolipants/features/profile/screens/profile_screen.dart';
import 'package:lolipants/features/profile/screens/settings_screen.dart';
import 'package:lolipants/features/role_request/screens/role_request_screen.dart';
import 'package:lolipants/features/sizing/screens/ai_measurement_screen.dart';
import 'package:lolipants/features/sizing/screens/manual_size_screen.dart';
import 'package:lolipants/features/sizing/screens/sizing_method_screen.dart';
import 'package:lolipants/features/sizing/screens/workshop_booking_screen.dart';
import 'package:lolipants/features/shell/main_shell.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/features/splash/screens/splash_screen.dart';

/// Root navigator key for imperative navigation from interceptors.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

bool _isShellLocation(String location) {
  const roots = ['/home', '/browse', '/orders', '/community', '/profile'];
  for (final root in roots) {
    if (location == root || location.startsWith('$root/')) {
      return true;
    }
  }
  return false;
}

bool _isTailorLocation(String location) {
  return location == '/tailor' || location.startsWith('/tailor/');
}

bool _isDeliveryLocation(String location) {
  return location == '/delivery' || location.startsWith('/delivery/');
}

bool _isAdminLocation(String location) {
  return location == '/admin' || location.startsWith('/admin/');
}

bool _isProtectedLocation(String location) {
  if (_isShellLocation(location)) return true;
  if (_isTailorLocation(location)) return true;
  if (_isDeliveryLocation(location)) return true;
  if (_isAdminLocation(location)) return true;
  if (location == '/sizing' || location.startsWith('/sizing/')) return true;
  if (location == '/order/summary' || location.startsWith('/order/'))
    return true;
  return location == '/editor' ||
      location.startsWith('/editor/') ||
      location == '/mannequin-selector';
}

bool _isCustomerShell(String location) {
  const roots = ['/home', '/browse', '/orders', '/community'];
  for (final root in roots) {
    if (location == root || location.startsWith('$root/')) return true;
  }
  return false;
}

/// Ordered scope-to-path map used when an admin lands on `/admin` without a
/// deeper location. Super admins (with `*` in [User.adminScopes]) fall through
/// to the stats screen.
const List<_AdminScopeRoute> _adminScopeRoutes = <_AdminScopeRoute>[
  _AdminScopeRoute(AdminScopes.usersMgmt, '/admin/users'),
  _AdminScopeRoute(AdminScopes.ordersOversight, '/admin/orders'),
  _AdminScopeRoute(AdminScopes.payouts, '/admin/payouts'),
  _AdminScopeRoute(AdminScopes.moderation, '/admin/moderation'),
  _AdminScopeRoute(AdminScopes.news, '/admin/news'),
  _AdminScopeRoute(AdminScopes.cms, '/admin/cms'),
  _AdminScopeRoute(AdminScopes.complaints, '/admin/complaints'),
];

class _AdminScopeRoute {
  const _AdminScopeRoute(this.scope, this.path);

  final String scope;
  final String path;
}

String? _defaultAdminLandingForUser(AuthState? state) {
  if (state is! AuthAuthenticated) return null;
  final user = state.user;
  if (!user.isAdmin) return null;
  if (user.isSuperAdmin) return '/admin/stats';
  for (final mapping in _adminScopeRoutes) {
    if (user.hasScope(mapping.scope)) return mapping.path;
  }
  return '/admin/stats';
}

String? _redirectLogic(AsyncValue<AuthState> auth, String location) {
  if (!kFeatureCommunity &&
      (location == '/community' || location.startsWith('/community/'))) {
    return '/home';
  }
  if (!kFeatureCasual) {
    final casualCategory = RegExp(r'^/browse/c/casual/?$');
    if (casualCategory.hasMatch(location)) {
      return '/browse';
    }
  }
  if (!kFeatureMens) {
    final menCategory = RegExp(r'^/browse/c/men/?$');
    if (menCategory.hasMatch(location)) {
      return '/browse';
    }
    final kidsCategory = RegExp(r'^/browse/c/kids/?$');
    if (kidsCategory.hasMatch(location)) {
      return '/browse';
    }
  }
  if (auth.isLoading) {
    if (location != '/') {
      return '/';
    }
    return null;
  }
  if (auth.hasError) {
    if (_isProtectedLocation(location)) {
      return '/login?returnTo=${Uri.encodeComponent(location)}';
    }
    return null;
  }
  final state = auth.value;
  if (state is AuthAuthenticated) {
    final user = state.user;
    final role = user.normalizedRole;
    final landing = homeForRole(user);

    if (location == '/login' || location == '/signup') {
      return landing;
    }

    // Cross-role gating: non-role users cannot see the other role shells.
    if (_isTailorLocation(location) && role != UserRoles.tailor) {
      return landing;
    }
    if (_isDeliveryLocation(location) && role != UserRoles.delivery) {
      return landing;
    }
    if (_isAdminLocation(location) && role != UserRoles.admin) {
      return landing;
    }

    // Tailor / delivery / admin accounts are kept out of the customer shell.
    if (role != UserRoles.user && _isCustomerShell(location)) {
      return landing;
    }

    return null;
  }
  if (_isProtectedLocation(location)) {
    return '/login?returnTo=${Uri.encodeComponent(location)}';
  }
  return null;
}

/// GoRouter instance wired to Riverpod auth refresh.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AsyncValue<AuthState>>(authProvider, (_, __) {
    refresh.value++;
  });
  ref.listen<Locale>(settingsLocaleProvider, (previous, next) {
    if (previous != next) refresh.value++;
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final pendingReturnTo = ref.read(pendingAuthReturnToProvider);
      if (state.matchedLocation == '/login' &&
          auth.value is AuthAuthenticated) {
        final authed = auth.value! as AuthAuthenticated;
        return pendingReturnTo ?? homeForRole(authed.user);
      }
      return _redirectLogic(auth, state.matchedLocation);
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot',
        name: 'forgot',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/sizing',
        name: 'sizingMethod',
        builder: (context, state) => const SizingMethodScreen(),
        routes: [
          GoRoute(
            path: 'ai',
            name: 'sizingAi',
            builder: (context, state) => const AiMeasurementScreen(),
          ),
          GoRoute(
            path: 'manual',
            name: 'sizingManual',
            builder: (context, state) => const ManualSizeScreen(),
          ),
          GoRoute(
            path: 'workshop',
            name: 'sizingWorkshop',
            builder: (context, state) => const WorkshopBookingScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/mannequin-selector',
        name: 'mannequinSelector',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is MannequinSelectorArgs) {
            return MannequinSelectorScreen(
              pendingPreset: extra.preset,
              homeFlow: extra.homeFlow,
            );
          }
          final pendingPreset =
              extra is EditorPresetArgs ? extra : null;
          return MannequinSelectorScreen(pendingPreset: pendingPreset);
        },
      ),
      GoRoute(
        path: '/browse/style/:styleId',
        name: 'browseStyle',
        builder: (context, state) {
          final id = state.pathParameters['styleId']!;
          return GarmentStyleScreen(styleId: id);
        },
      ),
      GoRoute(
        path: '/browse/c/:category',
        name: 'browseCategory',
        builder: (context, state) {
          final slug = state.pathParameters['category']!;
          return CategoryDetailScreen(category: slug);
        },
      ),
      GoRoute(
        path: '/wedding/fulfillment',
        name: 'weddingFulfillment',
        builder: (context, state) => const WeddingFulfillmentScreen(),
      ),
      GoRoute(
        path: '/wedding/dresses',
        name: 'weddingDresses',
        builder: (context, state) {
          final extra = state.extra;
          final flowArgs = extra is WeddingFlowArgs ? extra : null;
          return WeddingDressBrowseScreen(flowArgs: flowArgs);
        },
      ),
      GoRoute(
        path: '/wedding/dress',
        name: 'weddingDressDetail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is WeddingDressDetailArgs) {
            return WeddingDressDetailScreen(
              dress: extra.dress,
              fulfillment: extra.fulfillment,
            );
          }
          final locale = ref.read(settingsLocaleProvider);
          return Scaffold(
            body: Center(
              child: Text(
                localizedFromLocale(
                  locale,
                  AppStrings.weddingSelectDressHint,
                  AppStrings.weddingSelectDressHintAr,
                ),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/order/summary',
        name: 'orderSummary',
        builder: (context, state) {
          final draft = state.extra is OrderDesignDraft
              ? state.extra! as OrderDesignDraft
              : null;
          return OrderSummaryScreen(designDraft: draft);
        },
      ),
      GoRoute(
        path: '/order/wedding-summary',
        name: 'orderWeddingSummary',
        builder: (context, state) {
          final draft = state.extra is WeddingOrderDraft
              ? state.extra! as WeddingOrderDraft
              : null;
          return OrderWeddingSummaryScreen(weddingDraft: draft);
        },
      ),
      GoRoute(
        path: '/order/wedding-quote-review',
        name: 'orderWeddingQuoteReview',
        builder: (context, state) => const OrderWeddingQuoteReviewScreen(),
      ),
      GoRoute(
        path: '/browse/accessory/:accessoryId',
        name: 'accessoryDetail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Accessory) {
            return AccessoryDetailScreen(accessory: extra);
          }
          final locale = ref.read(settingsLocaleProvider);
          return Scaffold(
            body: Center(
              child: Text(
                localizedFromLocale(
                  locale,
                  AppStrings.accessoryNotFound,
                  AppStrings.accessoryNotFoundAr,
                ),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/order/accessory-summary',
        name: 'orderAccessorySummary',
        builder: (context, state) {
          final draft = state.extra is AccessoryOrderDraft
              ? state.extra! as AccessoryOrderDraft
              : null;
          return OrderAccessorySummaryScreen(accessoryDraft: draft);
        },
      ),
      GoRoute(
        path: '/order/accessory-quote-review',
        name: 'orderAccessoryQuoteReview',
        builder: (context, state) => const OrderAccessoryQuoteReviewScreen(),
      ),
      GoRoute(
        path: '/order/size-confirm',
        name: 'orderSizeConfirm',
        builder: (context, state) => const SizeConfirmationScreen(),
      ),
      GoRoute(
        path: '/order/delivery',
        name: 'orderDelivery',
        builder: (context, state) => const DeliveryDetailsScreen(),
      ),
      GoRoute(
        path: '/order/quote-review',
        name: 'orderQuoteReview',
        builder: (context, state) => const OrderQuoteReviewScreen(),
      ),
      GoRoute(
        path: '/order/quote-negotiation/:negotiationId',
        name: 'orderQuoteNegotiation',
        builder: (context, state) {
          final id = state.pathParameters['negotiationId']!;
          return QuoteNegotiationDetailScreen(negotiationId: id);
        },
      ),
      GoRoute(
        path: '/order/payment',
        name: 'orderPayment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/order/confirmed/:orderId',
        name: 'orderConfirmed',
        builder: (context, state) {
          final id = state.pathParameters['orderId']!;
          return OrderConfirmationScreen(orderId: id);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return TailorShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tailor/incoming',
                name: 'tailorIncoming',
                builder: (context, state) => const TailorIncomingOrdersScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:orderId',
                    name: 'tailorIncomingDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['orderId']!;
                      return TailorOrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tailor/price-requests',
                name: 'tailorPriceRequests',
                builder: (context, state) => const TailorPriceRequestsScreen(),
                routes: [
                  GoRoute(
                    path: ':negotiationId',
                    name: 'tailorPriceRequestDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['negotiationId']!;
                      return TailorQuoteNegotiationDetailScreen(
                        negotiationId: id,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tailor/active',
                name: 'tailorActive',
                builder: (context, state) => const TailorActiveOrdersScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:orderId',
                    name: 'tailorActiveDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['orderId']!;
                      return TailorOrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tailor/completed',
                name: 'tailorCompleted',
                builder: (context, state) =>
                    const TailorCompletedOrdersScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:orderId',
                    name: 'tailorCompletedDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['orderId']!;
                      return TailorOrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tailor/pricing',
                name: 'tailorPricing',
                builder: (context, state) => const TailorPricingScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DeliveryShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/queue',
                name: 'deliveryQueue',
                builder: (context, state) => const DeliveryQueueScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:orderId',
                    name: 'deliveryQueueDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['orderId']!;
                      return DeliveryOrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/active',
                name: 'deliveryActive',
                builder: (context, state) => const DeliveryActiveScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:orderId',
                    name: 'deliveryActiveDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['orderId']!;
                      return DeliveryOrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/history',
                name: 'deliveryHistory',
                builder: (context, state) => const DeliveryHistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:orderId',
                    name: 'deliveryHistoryDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['orderId']!;
                      return DeliveryOrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            name: 'adminRoot',
            redirect: (context, state) {
              if (state.matchedLocation == '/admin') {
                return _defaultAdminLandingForUser(
                    ref.read(authProvider).value);
              }
              return null;
            },
            builder: (context, state) => const AdminStatsScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'adminUsers',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/role-requests',
            name: 'adminRoleRequests',
            builder: (context, state) => const AdminRoleRequestsScreen(),
          ),
          GoRoute(
            path: '/admin/orders',
            name: 'adminOrders',
            builder: (context, state) => const AdminOrdersScreen(),
          ),
          GoRoute(
            path: '/admin/payouts',
            name: 'adminPayouts',
            builder: (context, state) => const AdminPayoutsScreen(),
          ),
          GoRoute(
            path: '/admin/moderation',
            name: 'adminModeration',
            builder: (context, state) => const AdminModerationScreen(),
          ),
          GoRoute(
            path: '/admin/news',
            name: 'adminNews',
            builder: (context, state) => const AdminNewsScreen(),
          ),
          GoRoute(
            path: '/admin/cms',
            name: 'adminCms',
            builder: (context, state) => const AdminCmsScreen(),
          ),
          GoRoute(
            path: '/admin/complaints',
            name: 'adminComplaints',
            builder: (context, state) => const AdminComplaintsScreen(),
          ),
          GoRoute(
            path: '/admin/stats',
            name: 'adminStats',
            builder: (context, state) => const AdminStatsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/editor',
        name: 'editor',
        builder: (context, state) {
          final extra = state.extra;
          String? mannequinId;
          EditorPresetArgs? preset;
          GarmentDesign? design;
          EditorBootstrapArgs? bootstrap;
          if (extra is EditorBootstrapArgs) {
            bootstrap = extra;
            mannequinId = bootstrap.mannequinId;
            preset = bootstrap.preset;
          } else if (extra is Map<String, dynamic>) {
            bootstrap = EditorBootstrapArgs.fromJson(extra);
            mannequinId = bootstrap.mannequinId;
            preset = bootstrap.preset;
          } else if (extra is String) {
            mannequinId = extra;
          } else if (extra is EditorPresetArgs) {
            preset = extra;
          } else if (extra is GarmentDesign) {
            design = extra;
          }
          return EditorScreen(
            initialMannequinId: mannequinId,
            preset: preset,
            design: design,
            bootstrap: bootstrap,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/browse',
                name: 'browse',
                builder: (context, state) => const BrowseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                name: 'orders',
                builder: (context, state) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:orderId',
                    name: 'orderDetail',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['orderId']!;
                      return OrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                name: 'community',
                builder: (context, state) => const CommunityScreen(),
                routes: [
                  GoRoute(
                    path: 'new-post',
                    name: 'communityNewPost',
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final prefill = state.extra is CreatePostPrefill
                          ? state.extra! as CreatePostPrefill
                          : null;
                      return MaterialPage<void>(
                        key: state.pageKey,
                        child: CreatePostScreen(prefill: prefill),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'news/:articleId',
                    name: 'communityNewsArticle',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['articleId']!;
                      return NewsArticleDetailScreen(articleId: id);
                    },
                  ),
                  GoRoute(
                    path: 'posts/:postId',
                    name: 'communityPostDetail',
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['postId']!;
                      final initialPost =
                          state.extra is Post ? state.extra! as Post : null;
                      return MaterialPage<void>(
                        key: state.pageKey,
                        child: PostDetailScreen(
                          postId: id,
                          initialPost: initialPost,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'designer/:designerId',
                    name: 'communityDesigner',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['designerId']!;
                      return DesignerProfileScreen(designerId: id);
                    },
                  ),
                  GoRoute(
                    path: 'earnings',
                    name: 'communityEarnings',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const DesignerEarningsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'designs',
                    name: 'myDesigns',
                    builder: (context, state) => const MyDesignsScreen(),
                  ),
                  GoRoute(
                    path: 'measurements',
                    name: 'myMeasurements',
                    builder: (context, state) => const MyMeasurementsScreen(),
                  ),
                  GoRoute(
                    path: 'price-negotiations',
                    name: 'myPriceNegotiations',
                    builder: (context, state) =>
                        const MyPriceNegotiationsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: 'profileSettings',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'role-request',
                    name: 'profileRoleRequest',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const RoleRequestScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    name: 'profileEdit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
