# Lolipants — Cursor Development Instructions

## Overview

You are building **Lolipants**, a premium Middle Eastern fashion design mobile app. Users design custom garments on a 3D mannequin, choose fabrics, add text or printed images, and place orders fulfilled by partner tailors and delivered to their door. The app also has a social/community layer where designers can showcase work and earn commissions.

This document covers **Phase 1 and Phase 2 (2A · 2B · 2C)** only. Read every section in full before writing any code.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (latest stable) |
| Language | Dart |
| State management | Riverpod (flutter_riverpod) |
| Navigation | go_router |
| Authentication | Better Auth (self-hosted) — see Auth section |
| Database | Cloudflare D1 (SQLite-compatible) via REST API |
| Storage | Cloudflare R2 (images, assets) |
| HTTP client | Dio with interceptors |
| Local storage | flutter_secure_storage (tokens), shared_preferences (settings) |
| Animations | flutter_animate, Rive (mascot) |
| Fonts | Poppins (Latin), Noto Naskh Arabic (Arabic) |
| Linting | flutter_lints, very_good_analysis |

**Do not use Firebase. Do not use Supabase. Do not use any Google auth SDKs.**
All backend calls go to a self-hosted Better Auth instance and Cloudflare Workers.

---

## Project Structure

```
lolipants/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   ├── app_spacing.dart
│   │   │   └── app_strings.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   └── api_endpoints.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       └── extensions.dart
│   ├── features/
│   │   ├── splash/
│   │   │   ├── screens/splash_screen.dart
│   │   │   └── widgets/mascot_animation.dart
│   │   ├── onboarding/
│   │   │   ├── screens/onboarding_screen.dart
│   │   │   └── widgets/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   └── auth_local_storage.dart
│   │   │   ├── providers/auth_provider.dart
│   │   │   └── screens/
│   │   │       ├── login_screen.dart
│   │   │       ├── signup_screen.dart
│   │   │       └── forgot_password_screen.dart
│   │   ├── shell/
│   │   │   └── main_shell.dart
│   │   ├── home/
│   │   │   ├── screens/home_screen.dart
│   │   │   └── widgets/
│   │   │       ├── home_header.dart
│   │   │       ├── hero_banner.dart
│   │   │       ├── category_pills.dart
│   │   │       ├── style_card.dart
│   │   │       └── style_grid.dart
│   │   ├── browse/
│   │   │   ├── screens/browse_screen.dart
│   │   │   └── widgets/
│   │   │       ├── country_card.dart
│   │   │       └── featured_strip.dart
│   │   ├── orders/
│   │   │   ├── models/
│   │   │   │   ├── order_status.dart
│   │   │   │   └── order.dart
│   │   │   ├── screens/
│   │   │   │   ├── orders_screen.dart
│   │   │   │   └── order_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── order_card.dart
│   │   │       ├── order_status_badge.dart
│   │   │       ├── order_status_timeline.dart
│   │   │       └── tailor_strip.dart
│   │   ├── community/
│   │   │   └── screens/community_screen.dart
│   │   └── profile/
│   │       ├── screens/profile_screen.dart
│   │       └── widgets/profile_tile.dart
│   └── shared/
│       ├── widgets/
│       │   ├── arabesque_background.dart
│       │   ├── lolipants_button.dart
│       │   ├── lolipants_text_field.dart
│       │   ├── bottom_nav_bar.dart
│       │   ├── error_banner.dart
│       │   ├── gold_divider.dart
│       │   ├── arabic_english_label.dart
│       │   └── loading_overlay.dart
│       └── models/
├── assets/
│   ├── animations/
│   ├── images/
│   └── fonts/
├── test/
├── pubspec.yaml
└── LOLIPANTS_CURSOR_INSTRUCTIONS.md
```

---

## Design System

Implement everything here before writing any screen. No hard-coded values anywhere.

### Colours

```dart
// core/constants/app_colors.dart
class AppColors {
  static const Color ink       = Color(0xFF0A0806);  // primary bg
  static const Color stone     = Color(0xFF14110D);  // card bg
  static const Color ember     = Color(0xFF1C1810);  // elevated surface
  static const Color smoke     = Color(0xFF252016);  // input bg

  static const Color gold      = Color(0xFFC9A84C);  // primary accent
  static const Color goldLight = Color(0xFFE2C06A);
  static const Color goldDark  = Color(0xFF7A6022);

  static const Color sand      = Color(0xFFF0E6D0);  // primary text
  static const Color dust      = Color(0xFFB8A882);  // secondary text
  static const Color fog       = Color(0xFF6A5E48);  // hint / disabled

  static const Color teal      = Color(0xFF1B4A42);
  static const Color tealLight = Color(0xFF4DAA8E);  // success / delivered

  static const Color ruby      = Color(0xFF6B1A1A);
  static const Color rubyLight = Color(0xFFCC4444);  // error / destructive

  static const Color borderSubtle  = Color(0x1AC9A84C);  // 10% gold
  static const Color borderDefault = Color(0x33C9A84C);  // 20% gold
  static const Color borderStrong  = Color(0x66C9A84C);  // 40% gold
}
```

### Typography

```dart
// core/constants/app_text_styles.dart
// Poppins for Latin, Noto Naskh Arabic for Arabic
class AppTextStyles {
  static TextStyle displayLarge  = Poppins, 28px, w500, sand
  static TextStyle displayMedium = Poppins, 22px, w500, sand
  static TextStyle titleLarge    = Poppins, 18px, w500, sand
  static TextStyle titleMedium   = Poppins, 15px, w500, sand
  static TextStyle titleSmall    = Poppins, 13px, w500, sand
  static TextStyle bodyLarge     = Poppins, 14px, w400, sand
  static TextStyle bodyMedium    = Poppins, 12px, w400, dust
  static TextStyle bodySmall     = Poppins, 11px, w400, fog
  static TextStyle labelGold     = Poppins, 10px, w500, gold, letterSpacing 0.1
  static TextStyle arabicBody    = Noto Naskh Arabic, 14px, w400, sand
  static TextStyle arabicLabel   = Noto Naskh Arabic, 11px, w500, gold
}
```

### Spacing & Radius

```dart
class AppSpacing {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32;
}

class AppRadius {
  static const double sm = 8, md = 12, lg = 16, xl = 20, pill = 100;
}
```

### Theme

```dart
ThemeData get appTheme => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.ink,
  colorScheme: ColorScheme.dark(
    primary: AppColors.gold,
    surface: AppColors.stone,
    error: AppColors.rubyLight,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
);
```

---

## Authentication — Better Auth

Self-hosted Better Auth only. No Firebase, no Supabase, no Google SDK.

### Endpoints

```
POST /auth/sign-up/email    — name, email, password
POST /auth/sign-in/email    — email, password
POST /auth/sign-out          — invalidate session
GET  /auth/get-session       — return session + user
POST /auth/forget-password   — send reset email
POST /auth/reset-password    — reset with token
```

### Token Storage

- Session token → `flutter_secure_storage` key: `lolipants_session_token`
- User object (id, name, email, role) → `flutter_secure_storage` key: `lolipants_user` (JSON)
- Never use `SharedPreferences` for tokens

### Auth Repository

```dart
abstract class AuthRepository {
  Future<Either<AppException, AuthResult>> signUp({required String name, required String email, required String password});
  Future<Either<AppException, AuthResult>> signIn({required String email, required String password});
  Future<Either<AppException, void>>       signOut();
  Future<Either<AppException, User?>>      getSession();
  Future<Either<AppException, void>>       forgotPassword(String email);
}
```

### Auth State

```dart
// AsyncNotifier with states:
//   AuthState.initial()                 — session not yet checked
//   AuthState.loading()
//   AuthState.authenticated(User user)
//   AuthState.unauthenticated()
//   AuthState.error(String message)

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

### Route Guard

```dart
// redirect in app_router.dart:
// initial/loading   → stay on splash, no redirect
// unauthenticated   → /login  (unless already on /login, /signup, /forgot, /onboarding)
// authenticated     → /home   (if currently on /login or /signup)
```

---

## Order Status Model

Order tracking is **status-based only**. No GPS, no maps, no location permissions. Status is updated by the tailor/admin backend and polled or pushed to the user's device.

```dart
// features/orders/models/order_status.dart
enum OrderStatus {
  placed,          // Received, awaiting tailor confirmation
  confirmed,       // Tailor accepted
  cutting,         // Fabric being cut
  stitching,       // Garment being stitched
  embroidery,      // Detail work / finishing
  qualityCheck,    // Final inspection
  readyToShip,     // Packed, handed to delivery
  outForDelivery,  // With rider, on the way
  delivered,       // Confirmed received
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get labelEn => const {
    OrderStatus.placed:          'Order placed',
    OrderStatus.confirmed:       'Confirmed by tailor',
    OrderStatus.cutting:         'Cutting fabric',
    OrderStatus.stitching:       'Stitching garment',
    OrderStatus.embroidery:      'Applying details',
    OrderStatus.qualityCheck:    'Quality check',
    OrderStatus.readyToShip:     'Ready to ship',
    OrderStatus.outForDelivery:  'Out for delivery',
    OrderStatus.delivered:       'Delivered',
    OrderStatus.cancelled:       'Cancelled',
  }[this]!;

  String get labelAr => const {
    OrderStatus.placed:          'تم تقديم الطلب',
    OrderStatus.confirmed:       'تم التأكيد من الخياط',
    OrderStatus.cutting:         'قص القماش',
    OrderStatus.stitching:       'خياطة الملبس',
    OrderStatus.embroidery:      'تطبيق التفاصيل',
    OrderStatus.qualityCheck:    'فحص الجودة',
    OrderStatus.readyToShip:     'جاهز للشحن',
    OrderStatus.outForDelivery:  'في الطريق إليك',
    OrderStatus.delivered:       'تم التسليم',
    OrderStatus.cancelled:       'ملغى',
  }[this]!;

  int  get step       => OrderStatus.values.indexOf(this) + 1;
  bool get isActive   => this != OrderStatus.delivered && this != OrderStatus.cancelled;
  bool get isDone     => this == OrderStatus.delivered;
  bool get isCancelled=> this == OrderStatus.cancelled;

  static const int totalActiveSteps = 8; // placed through outForDelivery
}
```

```dart
// features/orders/models/order.dart
class Order {
  final String id;
  final String designName;
  final String tailorName;
  final OrderStatus status;
  final DateTime placedAt;
  final DateTime? estimatedDelivery;
  final List<OrderStatusUpdate> statusHistory;
}

class OrderStatusUpdate {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;
}
```

---

## API Layer

```dart
// core/network/dio_client.dart
class DioClient {
  static Dio create() {
    final dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.addAll([
      AuthInterceptor(),   // reads token from secure storage → Authorization header
                           // on 401: clear token → navigate to /login
      LogInterceptor(),    // debug builds only
      ErrorInterceptor(),  // HTTP errors → AppException
    ]);
    return dio;
  }
}
```

## Error Handling

```dart
sealed class AppException { const AppException(); }
class NetworkException  extends AppException { final String message; }
class AuthException     extends AppException { final String message; }
class ServerException   extends AppException { final int statusCode; final String message; }
class UnknownException  extends AppException {}
```

All repository methods return `Either<AppException, T>` via `fpdart`. No raw try/catch in UI.

---

## Environment

```env
# .env — add to .gitignore
BETTER_AUTH_BASE_URL=https://your-better-auth-instance.com
API_BASE_URL=https://your-cloudflare-worker.com/api
CLOUDFLARE_R2_BASE_URL=https://your-r2-bucket.com
```

---

## Localisation Rules (Phases 1–2)

- All user-facing strings in `AppStrings` — both EN and AR
- Arabic text uses `Noto Naskh Arabic` font always
- Wrap Arabic text in `Directionality(textDirection: TextDirection.rtl, child: ...)`
- Do **not** set up full `flutter_localizations` yet — Phase 3+
- Do **not** force app-wide RTL yet

---

## Code Quality

1. No `print()` — use `logging` package
2. No hard-coded strings in widgets — use `AppStrings`
3. No hard-coded colours in widgets — use `AppColors`
4. No business logic in `build()` — use providers / use-cases
5. Every public class and method has a doc comment
6. One primary widget class per file
7. `build()` methods under 80 lines — extract aggressively
8. Every `async` call handles loading + error states visibly

---

## pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.0.0
  dio: ^5.4.3
  flutter_dotenv: ^5.1.0
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.2
  fpdart: ^1.1.0
  flutter_animate: ^4.5.0
  rive: ^0.13.2
  google_fonts: ^6.2.1
  intl: ^0.19.0
  logging: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  very_good_analysis: ^6.0.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3
```

---

---

# PHASE 1 — Foundation & Design System
### Days 1–2 · Complete fully before Phase 2A

---

## Tasks

### 1.1 Project Bootstrap
- `flutter create lolipants --org com.lolipants --platforms android,ios`
- Add all dependencies, configure Android minSdk 24 / targetSdk 34, iOS deployment 14.0
- Set up `.env` + `flutter_dotenv`, load in `main.dart` before `runApp`
- Create complete folder structure as above
- Configure `very_good_analysis` linting

### 1.2 Design System
Implement `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, `AppTheme`, and `AppStrings` exactly as specified. Include every string below in `AppStrings`:

```dart
// Bilingual string pairs (add all that are needed; extend as screens are built)
appName / appNameAr           = 'Lolipants' / 'لوليبانتس'
tagline / taglineAr           = 'wear your heritage' / 'ارتدِ تراثك'
welcomeBack / welcomeBackAr   = 'Welcome back' / 'مرحباً بعودتك'
createAccount / createAccountAr
logIn / logInAr
logOut / logOutAr
forgotPassword / forgotPasswordAr
fullName / fullNameAr
email / emailAr
password / passwordAr
confirmPassword / confirmPasswordAr
home / homeAr
browse / browseAr
orders / ordersAr
community / communityAr
profile / profileAr
myOrders / myOrdersAr
noOrdersYet / noOrdersYetAr
startDesigning / startDesigningAr
traditionalStyles / traditionalStylesAr
seeAll / seeAllAr
goodMorning / goodMorningAr
goodAfternoon / goodAfternoonAr
goodEvening / goodEveningAr
aiDesigner / aiDesignerAr     = 'AI Designer' / 'مصمم ذكي'
describeOutfit / describeOutfitAr
tryNow / tryNowAr
trackOrder / trackOrderAr
comingSoon / comingSoonAr     = 'Coming soon' / 'قريباً'
```

### 1.3 Shared Widgets

**ArabesqueBackground**
- `CustomPainter` — repeating hexagonal lattice
- Each cell: outer hex outline + inner hex at 0.6 scale + 8-pointed star at centre
- Stroke: `AppColors.gold`, 0.5px
- `opacity` parameter, default 0.04
- Covers parent size, `IgnorePointer` wrapper

**LolipantsButton**
- Variants: `primary` (gold bg, ink text) · `secondary` (transparent, gold border + text) · `destructive` (transparent, ruby border + text)
- Full width, height 52px, `AppRadius.md`
- Loading state: `CircularProgressIndicator` (gold, strokeWidth 2, size 20)
- Disabled state: 0.4 opacity

**LolipantsTextField**
- Background: `AppColors.smoke`
- Borders: default `borderSubtle` 1px → focused `gold` 1.5px → error `rubyLight` 1.5px
- Floating label in `AppColors.dust`
- Error text below in `AppColors.rubyLight`, 11px
- Password obscure toggle, prefix/suffix icon support

**ArabicEnglishLabel**
- Arabic text (RTL, `arabicLabel` style) stacked above English text (`labelGold` style)
- `crossAxisAlignment` configurable

**GoldDivider**
- 1px horizontal line, `AppColors.borderSubtle`
- Optional `width` (default full), optional `centred` flag

**ErrorBanner**
- `AppColors.ruby` background, `AppRadius.md`, padding 12px
- Row: ruby warning icon + message text (`AppColors.sand`, 12px)
- Animated: `slideY` + `fadeIn` on appear (flutter_animate, 200ms)
- Auto-dismiss after 5 seconds; tappable X to close early

**LoadingOverlay**
- Full-screen Stack: `AppColors.ink` at 0.85 opacity
- Centred `CircularProgressIndicator` in `AppColors.gold`
- Absorbs all pointer events

**LolipantsBottomNavBar**
- 5 items: Home · Browse · Orders · Community · Profile
- Active: icon + label in `AppColors.gold` + 3px gold dot below label
- Inactive: icon + label in `AppColors.fog`
- Background `AppColors.ink`, top border 1px `borderSubtle`
- Height 64px (excluding safe area), no elevation, no ink splash
- `currentIndex` + `onTap` callback

### 1.4 Splash Screen

**Behaviour:**
1. Minimum 2.5 seconds display
2. Call `authProvider.getSession()` on mount
3. Session valid → `/home` (replace)
4. No session + `has_seen_onboarding == false` → `/onboarding`
5. No session + flag seen → `/login`
6. Any error → `/login` silently

**UI (Stack layers, bottom to top):**
- `AppColors.ink` fill
- `ArabesqueBackground(opacity: 0.04)`
- 10–12 randomly positioned star dots (1.5–2.5px circles, `AppColors.sand`, 0.2–0.5 opacity)
- Centre column:
  - Rive placeholder: `Container(130×160)` with static panda image asset
  - Arabic name `لوليبانتس` — `displayMedium`, gold, letterSpacing 0.15
  - Latin `LOLIPANTS` — 9px, gold, letterSpacing 0.22
  - `GoldDivider(width: 32, centred: true)`
  - Tagline `AppStrings.taglineAr` / `AppStrings.tagline` — `bodySmall`
  - 3-dot loader: active = gold pill (22×4px), inactive = 6×6px circle 0.22 opacity

**Animation (flutter_animate, play on mount):**
```
0ms    logo container:  fadeIn 600ms
400ms  Arabic name:     slideY(begin: 0.3) + fadeIn 500ms
700ms  Latin name:      fadeIn 300ms
900ms  divider:         scaleX(begin: 0.0) 300ms from centre
1100ms tagline:         fadeIn 300ms
```

### 1.5 Onboarding Screen

**Behaviour:**
- `PageView`, 3 slides, `BouncingScrollPhysics`
- "Skip" top-right on slides 1–2 → sets `has_seen_onboarding = true` → `/login`
- Slide 3 CTA "Get started / ابدأ" → sets flag → `/signup`

**Slides:**

| # | EN Title | AR Title | EN Body |
|---|---|---|---|
| 1 | Design your fashion | صمم أزياءك | Create custom garments on a 3D mannequin |
| 2 | Rooted in heritage | مستوحى من تراثك | Traditional Gulf styles, reimagined |
| 3 | Made by master tailors | مصنوع بأيدي محترفين | Order and track your garment from stitch to door |

**Per slide UI:**
- Full screen: `AppColors.ink` + `ArabesqueBackground`
- Top 55%: illustration placeholder (`Container` + centred icon, gold scheme)
- Bottom 45%: `AppColors.stone` container, `BorderRadius.vertical(top: AppRadius.xl)`
  - Arabic title (`displayMedium`, gold, RTL)
  - English title (`titleLarge`, sand)
  - Body (`bodyMedium`, dust)
  - Page dots: active = gold pill 24×4px, inactive = 6px circle 0.25 opacity
  - CTA button

---

## Definition of Done — Phase 1

- [ ] Runs without errors on Android (API 24+) and iOS (14+)
- [ ] Design system fully implemented, zero hard-coded values
- [ ] All 8 shared widgets built and isolated
- [ ] Splash animation plays correctly, routes based on session + onboarding flag
- [ ] Onboarding swipes correctly, skip/CTA navigate and set flag
- [ ] `has_seen_onboarding` persists across cold starts

---

---

# PHASE 2A — Authentication
### Days 3–4 · Complete Phase 1 before starting

---

## Goal
Wire all auth screens to Better Auth. Users can sign up, log in, recover a password, and be protected by a route guard.

---

## 2A.1 Auth Infrastructure (build before screens)

1. `AuthLocalStorage` — typed read/write/clear for token + user via `flutter_secure_storage`
2. `DioClient` — with `AuthInterceptor` (token header, 401 → clear + redirect), `LogInterceptor` (debug only), `ErrorInterceptor`
3. `AuthRepository` implementation — all 5 methods returning `Either<AppException, T>`
4. `AuthNotifier` + `authProvider` — calls `getSession()` on construction to rehydrate from secure storage
5. Route guard in `app_router.dart` as specified

---

## 2A.2 Sign Up Screen

**Fields:** Full name · Email · Password · Confirm password

**Validation (client-side first):**
- Name: required, min 2 chars
- Email: valid format
- Password: min 8 chars, at least 1 digit
- Confirm password: must match

**Behaviour:**
1. Validate → if invalid, show field-level errors
2. Valid → `LoadingOverlay` → `authRepository.signUp()`
3. `Right` → store token + user → navigate `/home` (replace all)
4. `Left` → hide overlay → show `ErrorBanner`

**UI:**
- `AppColors.ink` + `ArabesqueBackground`
- Header: back chevron · "Create account" centred · `إنشاء حساب` below in `arabicLabel`
- `GoldDivider(width: 40, centred: true)` below header
- Fields with 16px gap
- `LolipantsButton(primary)` — "Create account / إنشاء حساب"
- Bottom: "Already have an account? " + gold tappable "Log in" → `/login`

---

## 2A.3 Log In Screen

**Fields:** Email · Password

**Behaviour:** same pattern as sign up — validate → overlay → `authRepository.signIn()` → store + navigate or show `ErrorBanner`

**Additional:**
- "Forgot password?" right-aligned below password field → `/forgot`
- "Don't have an account? Sign up" bottom → `/signup`

**UI:** mirrors sign-up. Title: "Welcome back / مرحباً بعودتك"

---

## 2A.4 Forgot Password Screen

**Field:** Email

**Behaviour:**
1. Validate → call `authRepository.forgotPassword(email)`
2. Success → replace form with confirmation:
   - Gold envelope icon (48px)
   - "Check your inbox / تحقق من بريدك الإلكتروني"
   - "We've sent a reset link to [email]"
   - `LolipantsButton(secondary)` "Back to log in" → `/login`
3. Error → `ErrorBanner`

---

## Definition of Done — Phase 2A

- [ ] Sign up creates user via Better Auth, stores token in secure storage
- [ ] Log in authenticates and stores token
- [ ] Forgot password sends email and shows confirmation state
- [ ] `authProvider` rehydrates state from stored token on cold start
- [ ] Route guard redirects unauthenticated users to `/login`
- [ ] Route guard redirects authenticated users away from `/login` and `/signup`
- [ ] `ErrorBanner` appears, auto-dismisses, and can be tapped closed
- [ ] `LoadingOverlay` blocks interaction during calls
- [ ] Zero Firebase, zero Supabase, zero Google SDK

---

---

# PHASE 2B — Main Shell & Home Screen
### Days 5–7 · Complete Phase 2A before starting

---

## Goal
Build the tab shell with bottom nav and deliver a fully rendered home screen with all sections.

---

## 2B.1 Main Shell

**File:** `features/shell/main_shell.dart`

```dart
Scaffold(
  body: child,
  bottomNavigationBar: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _MusicPlayerSlot(),      // 56px placeholder, full wiring in Phase 4
      LolipantsBottomNavBar(...),
    ],
  ),
)
```

`_MusicPlayerSlot`: `Container` 56px, `AppColors.stone`, top border 1px `borderSubtle`, centred Row of music note icon + "Music player" label (both `AppColors.fog`, 11px).

Use `StatefulShellRoute` in go_router so each tab maintains its own navigation stack independently.

---

## 2B.2 Home Screen

Build each section as its own widget in `features/home/widgets/`.

**HomeHeader** (`home_header.dart`)
- Time-of-day greeting (morning <12, afternoon 12–17, evening 17+): Arabic above English
- User name from `authProvider` in `titleLarge` + gold `✦`
- Circular avatar: 28px radius, `AppColors.ember` bg, 1.5px `borderDefault` border, initials in `AppColors.gold`

**HeroBanner** (`hero_banner.dart`)
- Container: 88px height, `AppColors.stone`, `AppRadius.lg`, 1px `borderSubtle`
- Left: `ArabicEnglishLabel` for "AI Designer" eyebrow · `describeOutfit` title · gold CTA pill "Try now →"
  - On tap: `ScaffoldMessenger` snack bar — "Coming in Phase 3"
- Right: arch + mannequin silhouette via `CustomPainter` at 0.25 opacity

**CategoryPills** (`category_pills.dart`)
- `SingleChildScrollView` horizontal, no scrollbar
- Pills: All · Men رجال · Women نساء · Kids أطفال · Wedding عرس · Accessories إكسسوارات
- Active: `AppColors.gold` bg, `AppColors.ink` text
- Inactive: `borderDefault` border, `AppColors.fog` text
- `StatefulWidget` — tapping updates active index locally only (no navigation yet)

**StyleCard** (`style_card.dart`)
- Image area: 58px, coloured background per garment
- Arch SVG via `CustomPainter` inside image area
- Title: `titleSmall` · Subtitle: `bodySmall` `AppColors.dust`
- `AppColors.stone` bg, `borderSubtle` border, `AppRadius.md`
- On tap: navigate to `/browse`

**StyleGrid** (`style_grid.dart`)
- Section header: "Traditional styles / الأزياء التقليدية" + "See all →" (`AppColors.gold`) → `/browse`
- `GridView.count(crossAxisCount: 2, crossAxisSpacing: 7, mainAxisSpacing: 7, shrinkWrap: true, physics: NeverScrollableScrollPhysics)`

**Hardcoded cards:**
```dart
[
  StyleCardData(title: 'Qatari Thobe',    subtitle: 'Qatar · 12 variants',   bg: Color(0xFF1A0F20)),
  StyleCardData(title: 'Saudi Bisht',     subtitle: 'Saudi · 8 variants',    bg: Color(0xFF0C1A0F)),
  StyleCardData(title: 'UAE Kandura',     subtitle: 'UAE · 6 variants',      bg: Color(0xFF181200)),
  StyleCardData(title: 'Omani Dishdasha', subtitle: 'Oman · 5 variants',     bg: Color(0xFF001610)),
]
```

**Home screen scroll structure:**
```dart
Stack(children: [
  ArabesqueBackground(),
  CustomScrollView(slivers: [
    SliverToBoxAdapter(child: HomeHeader()),
    SliverToBoxAdapter(child: HeroBanner()),
    SliverToBoxAdapter(child: CategoryPills()),
    SliverToBoxAdapter(child: StyleGrid()),       // includes section header + grid
    SliverToBoxAdapter(child: SizedBox(height: 24)),
  ]),
])
```

---

## Definition of Done — Phase 2B

- [ ] Main shell renders with bottom nav and music player slot
- [ ] All 5 tabs switch with independent stack per tab
- [ ] Home screen renders all 4 sections with correct styling
- [ ] Greeting changes correctly by time of day
- [ ] User name and initials come from auth state
- [ ] Category pills update active state on tap
- [ ] "See all" navigates to Browse tab
- [ ] Hero banner CTA shows correct snack bar
- [ ] All 4 style cards render with correct colours and arch CustomPainters
- [ ] Screen scrolls correctly with safe area handling on all sizes

---

---

# PHASE 2C — Tab Stubs & Order Status Tracker
### Days 8–10 · Complete Phase 2B before starting

---

## Goal
Build meaningful stubs for Browse, Orders, Community, and Profile. The Orders screen must show the full `OrderStatus` pipeline with mock data — real order wiring is Phase 5.

---

## 2C.1 Browse Screen

**File:** `features/browse/screens/browse_screen.dart`

**UI top to bottom:**
- Header: `الأزياء التقليدية` (arabicLabel, gold) above "Traditional styles" (titleLarge) · subtitle "Choose your region" (bodyMedium, dust)
- Region pills (same component as CategoryPills): Gulf · Modern · Levant
- 2×2 `GridView` of `CountryCard` widgets
- `FeaturedStrip` at bottom

**CountryCard** (`browse/widgets/country_card.dart`)
- 54px image area: coloured bg + arch `CustomPainter` (gold tones)
- Country code badge: top-right, `AppColors.gold` 6.5px text, `borderSubtle` bg, 4px radius
- Country name: `titleSmall`
- Garments: `bodySmall`, `AppColors.dust`
- On tap: snack bar "Coming in Phase 3"

```dart
const countries = [
  CountryData(name: 'Qatar',        code: 'QA', garments: 'Thobe · Bisht · Abaya',  bg: Color(0xFF130D1F)),
  CountryData(name: 'Saudi Arabia', code: 'SA', garments: 'Thobe · Bisht · Kaftan', bg: Color(0xFF0C180F)),
  CountryData(name: 'UAE',          code: 'AE', garments: 'Kandura · Abaya',        bg: Color(0xFF181200)),
  CountryData(name: 'Oman',         code: 'OM', garments: 'Dishdasha · Kumma',      bg: Color(0xFF001610)),
];
```

**FeaturedStrip** (`browse/widgets/featured_strip.dart`)
- `AppColors.stone`, `AppRadius.md`, `borderDefault` border, padding 10px
- Gold eyebrow "Featured · مميز" (`labelGold`)
- Body: "Hand-embroidered Jalabiya with traditional motifs" (`bodyMedium`)
- Row: 12px gold line + "Gulf collection · 2025" (`bodySmall`, gold)

---

## 2C.2 Orders Screen

**File:** `features/orders/screens/orders_screen.dart`

**Header:**
- Left: `طلباتي` (arabicLabel) above "My orders" (titleLarge)
- Right: "Filter" pill button (`secondary` outline, no action yet)

**Empty state** (when orders list is empty):
- Centred column: gold 8-pointed star icon (48px CustomPaint) · `noOrdersYet` · `noOrdersYetAr` · `LolipantsButton(secondary)` "Start designing" → `/home`

**Order list** (use `mockOrders` below):
- `ListView` of `OrderCard` widgets
- Below the first active order: `TailorStrip` + "Track order" button → `OrderDetailScreen`

**OrderCard** (`orders/widgets/order_card.dart`)
```
Row 1: "Order #XXXX" (bodySmall, dust) + OrderStatusBadge
Row 2: "Design" label (dust) + design name (titleSmall)
Row 3: "Tailor" label (dust) + tailor name (bodyMedium)
Row 4: current status note text (tealLight, 7.5px)
Progress bar: 3px height
  - bg: borderSubtle
  - fill: gold if active, tealLight if delivered, rubyLight if cancelled
  - width: (status.step / OrderStatus.totalActiveSteps) * maxWidth
```

**OrderStatusBadge** (`orders/widgets/order_status_badge.dart`)
```
Pill, 7px bold text, colours:
  placed/confirmed/cutting/stitching/embroidery → gold bg (10% opacity), gold text
  qualityCheck/readyToShip/outForDelivery       → dust bg (10% opacity), dust text
  delivered                                      → tealLight bg (12%), tealLight text
  cancelled                                      → rubyLight bg (12%), rubyLight text
```

**OrderStatusTimeline** (`orders/widgets/order_status_timeline.dart`)
- Vertical list of all `OrderStatus` values (excluding `cancelled` unless order is cancelled)
- Past step: filled gold circle 8px + gold label (titleSmall) + timestamp (bodySmall, dust)
- Current step: filled gold circle 10px + gold label + "In progress" tag (pulsing opacity via flutter_animate) + note if available
- Future step: empty circle 8px (`borderSubtle` stroke) + fog label
- Connecting lines: 1px, gold for completed segments, `borderSubtle` for upcoming
- Used inside `OrderDetailScreen`

**OrderDetailScreen** (`orders/screens/order_detail_screen.dart`)
- Header: "Order #XXXX" + back chevron
- `OrderStatusTimeline` widget (full list)
- Below: `TailorStrip` + estimated delivery date

**TailorStrip** (`orders/widgets/tailor_strip.dart`)
- Row: avatar circle (32px, initials, `ember` bg, `borderDefault` border) + Column(name, location, star rating) + estimated delivery right-aligned (gold)

**Mock orders:**
```dart
final mockOrders = [
  Order(
    id: '0042',
    designName: 'Teal Abaya · Gold trim',
    tailorName: 'Abdullah Workshop',
    status: OrderStatus.embroidery,
    placedAt: DateTime.now().subtract(const Duration(days: 3)),
    estimatedDelivery: DateTime.now().add(const Duration(days: 6)),
    statusHistory: [
      OrderStatusUpdate(status: OrderStatus.placed,     timestamp: now - 3d),
      OrderStatusUpdate(status: OrderStatus.confirmed,  timestamp: now - 2d, 16h),
      OrderStatusUpdate(status: OrderStatus.cutting,    timestamp: now - 2d),
      OrderStatusUpdate(status: OrderStatus.stitching,  timestamp: now - 1d),
      OrderStatusUpdate(status: OrderStatus.embroidery, timestamp: now - 4h, note: 'Gold trim being applied'),
    ],
  ),
  Order(
    id: '0038',
    designName: 'White Kandura · Classic',
    tailorName: 'Al-Rashidi Tailors',
    status: OrderStatus.delivered,
    placedAt: DateTime.now().subtract(const Duration(days: 12)),
    estimatedDelivery: DateTime.now().subtract(const Duration(days: 2)),
    statusHistory: [ /* all statuses with timestamps */ ],
  ),
];
```

---

## 2C.3 Community Screen

**File:** `features/community/screens/community_screen.dart`

Three tappable `SectionCard` widgets (each triggers snack bar "Coming in Phase 4"):

```dart
const sections = [
  SectionData(
    titleEn: 'Fashion news',     titleAr: 'أخبار الموضة',
    subtitleEn: 'Latest drops and trends',
    subtitleAr: 'آخر الأخبار والاتجاهات',
  ),
  SectionData(
    titleEn: 'Designer showcase', titleAr: 'معرض المصممين',
    subtitleEn: 'Designs that earn commission',
    subtitleAr: 'تصاميم تكسب عمولة',
  ),
  SectionData(
    titleEn: 'Consultations',     titleAr: 'الاستشارات',
    subtitleEn: 'Get advice on your design',
    subtitleAr: 'احصل على نصيحة لتصميمك',
  ),
];
```

`SectionCard`: `AppColors.stone`, `borderDefault`, `AppRadius.lg`, padding 14px. Row of 24px gold CustomPaint icon + Column(title `titleMedium`, subtitle `bodyMedium` dust).

---

## 2C.4 Profile Screen

**File:** `features/profile/screens/profile_screen.dart`

- Large avatar: 80px radius, initials, `ember` bg, 2px `borderStrong`
- User name (`titleLarge`) + email (`bodyMedium`, dust) from `authProvider`
- `GoldDivider`
- List of `ProfileTile` widgets:

```dart
tiles = [
  ProfileTile(labelEn: 'My designs',      labelAr: 'تصاميمي',         icon: DesignIcon),
  ProfileTile(labelEn: 'My measurements', labelAr: 'مقاساتي',         icon: MeasureIcon),
  ProfileTile(labelEn: 'Notifications',   labelAr: 'الإشعارات',       icon: NotifIcon),
  ProfileTile(labelEn: 'Settings',        labelAr: 'الإعدادات',       icon: SettingsIcon),
  ProfileTile(labelEn: 'Log out',         labelAr: 'تسجيل الخروج',    icon: LogoutIcon, isDestructive: true),
]
```

All tiles except Log Out show snack bar "Coming soon / قريباً".

**Log out flow:**
1. `showDialog` — "Log out? / تسجيل الخروج؟" with Cancel + Confirm (destructive)
2. On confirm: `authRepository.signOut()` → clear secure storage → `context.go('/login')` with `extra: {'replaceAll': true}`

---

## Definition of Done — Phase 2C

- [ ] Browse screen renders country grid and featured strip correctly
- [ ] Country cards show correct region colours and arch SVGs
- [ ] Orders screen shows empty state when no orders
- [ ] Orders screen shows order cards with correct badges and progress bars from mock data
- [ ] `OrderStatus` enum has all 10 statuses with correct EN and AR labels
- [ ] `OrderStatusTimeline` correctly renders past / current (pulsing) / future steps
- [ ] `OrderDetailScreen` shows full timeline with mock history
- [ ] Community stub shows 3 section cards, snack bar on tap
- [ ] Profile screen shows user data from auth state
- [ ] Log out shows confirmation dialog, clears token, navigates to `/login`
- [ ] All screens display correct Arabic labels
- [ ] No GPS, no maps, no location permissions anywhere in the project

---

---

## What NOT to Build in Phases 1–2

- 3D mannequin or design editor (Phase 3)
- Fabric selectors or design tools (Phase 3)
- AI assistant or camera sizing (Phase 3)
- Full RTL / intl localisation (Phase 3+)
- Wedding or sizing-specific screens (Phase 3)
- Live news feed or community posting (Phase 4)
- Real order creation or submission (Phase 5)
- Tap Payments integration (Phase 5)
- Tailor dashboard (Phase 5)
- Admin panel (Phase 5)
- Push notifications (Phase 5)

---

*End of Phase 1 and Phase 2 (2A · 2B · 2C) instructions.*
*Phase 3 — 3D Editor, AI & Sizing System — will be provided as a separate document.*
