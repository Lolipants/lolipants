# Lolipants — Cursor Development Instructions

## Overview

You are building **Lolipants**, a premium Middle Eastern fashion design mobile app. Users design custom garments on a 3D mannequin, choose fabrics, add text or printed images, and place orders that are fulfilled by partner tailors and delivered via GPS-tracked delivery. The app also has a social/community layer where designers can showcase work and earn commissions.

This document covers **Phase 1 and Phase 2** of development only. Read every section before writing any code.

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
| Animations | flutter_animate, Rive (for mascot) |
| Fonts | Google Fonts — use Poppins for Latin, Noto Naskh Arabic for Arabic |
| Linting | flutter_lints, very_good_analysis |

**Do not use Firebase. Do not use Supabase. Do not use any Google auth SDKs.**
All backend calls go to a self-hosted Better Auth instance and Cloudflare Workers.

---

## Project Structure

```
lolipants/
├── lib/
│   ├── main.dart
│   ├── app.dart                        # MaterialApp + router setup
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   ├── app_spacing.dart
│   │   │   └── app_strings.dart        # bilingual strings (EN + AR)
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
│   │   │   ├── screens/
│   │   │   │   └── splash_screen.dart
│   │   │   └── widgets/
│   │   │       └── mascot_animation.dart
│   │   ├── onboarding/
│   │   │   ├── screens/
│   │   │   │   └── onboarding_screen.dart
│   │   │   └── widgets/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   └── auth_local_storage.dart
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   └── screens/
│   │   │       ├── login_screen.dart
│   │   │       ├── signup_screen.dart
│   │   │       └── forgot_password_screen.dart
│   │   └── home/
│   │       ├── screens/
│   │       │   └── home_screen.dart
│   │       └── widgets/
│   │           ├── hero_banner.dart
│   │           ├── category_pills.dart
│   │           └── style_card.dart
│   └── shared/
│       ├── widgets/
│       │   ├── lolipants_button.dart
│       │   ├── lolipants_text_field.dart
│       │   ├── bottom_nav_bar.dart
│       │   └── loading_overlay.dart
│       └── models/
├── assets/
│   ├── animations/          # Rive files for panda mascot
│   ├── images/
│   └── fonts/
├── test/
├── pubspec.yaml
└── LOLIPANTS_CURSOR_INSTRUCTIONS.md  # this file
```

---

## Design System

Implement this design system first in `core/constants/` before building any screens.

### Colour Palette

```dart
// app_colors.dart
class AppColors {
  // Backgrounds
  static const Color ink       = Color(0xFF0A0806);  // primary background
  static const Color stone     = Color(0xFF14110D);  // card background
  static const Color ember     = Color(0xFF1C1810);  // elevated surface
  static const Color smoke     = Color(0xFF252016);  // input background

  // Brand
  static const Color gold      = Color(0xFFC9A84C);  // primary accent
  static const Color goldLight = Color(0xFFE2C06A);  // hover/highlight
  static const Color goldDark  = Color(0xFF7A6022);  // pressed state

  // Text
  static const Color sand      = Color(0xFFF0E6D0);  // primary text
  static const Color dust      = Color(0xFFB8A882);  // secondary text
  static const Color fog       = Color(0xFF6A5E48);  // hint/disabled text

  // Semantic
  static const Color teal      = Color(0xFF1B4A42);
  static const Color tealLight = Color(0xFF4DAA8E);  // success / delivered
  static const Color ruby      = Color(0xFF6B1A1A);
  static const Color rubyLight = Color(0xFFCC4444);  // error / destructive

  // Borders
  static const Color borderSubtle  = Color(0x1AC9A84C);  // 10% gold
  static const Color borderDefault = Color(0x33C9A84C);  // 20% gold
  static const Color borderStrong  = Color(0x66C9A84C);  // 40% gold
}
```

### Typography

```dart
// app_text_styles.dart
// Use Google Fonts — Poppins for Latin, Noto Naskh Arabic for Arabic
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
// app_spacing.dart
class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 24;
  static const double xxl = 32;
}

class AppRadius {
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double pill= 100;
}
```

### Theme

```dart
// app_theme.dart
ThemeData get appTheme => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.ink,
  colorScheme: ColorScheme.dark(
    primary: AppColors.gold,
    surface: AppColors.stone,
    error: AppColors.rubyLight,
  ),
  // No splash, no highlight — everything custom
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
);
```

---

## Authentication — Better Auth

The app uses a **self-hosted Better Auth** instance. Do not use Firebase Auth or any OAuth provider SDK directly. All auth calls go through Better Auth's REST endpoints.

### Endpoints (configure base URL via environment)

```
POST /auth/sign-up/email          — register with email + password
POST /auth/sign-in/email          — login with email + password
POST /auth/sign-out                — logout (clears session)
GET  /auth/get-session             — returns current session/user
POST /auth/forget-password         — sends reset email
POST /auth/reset-password          — resets with token
```

### Token Storage

- Store the session token in `flutter_secure_storage` under key `lolipants_session_token`
- Store user data (id, name, email, role) in `flutter_secure_storage` as JSON
- Never store tokens in SharedPreferences

### Auth Repository

```dart
// auth_repository.dart
class AuthRepository {
  final Dio _dio;

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<User?> getSession();

  Future<void> forgotPassword(String email);
}
```

### Auth State (Riverpod)

```dart
// auth_provider.dart
// Use AsyncNotifier for auth state
// States: unauthenticated | loading | authenticated(User) | error(String)

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
```

### Route Guard

In `app_router.dart`, implement a redirect that:
- Sends unauthenticated users to `/login`
- Sends authenticated users away from `/login` and `/signup` to `/home`
- Checks session on cold start before routing

---

## Routing — go_router

```dart
// app_router.dart
final routes = [
  GoRoute(path: '/',          builder: SplashScreen),
  GoRoute(path: '/onboarding',builder: OnboardingScreen),
  GoRoute(path: '/login',     builder: LoginScreen),
  GoRoute(path: '/signup',    builder: SignupScreen),
  GoRoute(path: '/forgot',    builder: ForgotPasswordScreen),
  ShellRoute(                 // main tab shell with BottomNavBar
    builder: MainShell,
    routes: [
      GoRoute(path: '/home',      builder: HomeScreen),
      GoRoute(path: '/browse',    builder: BrowseScreen),
      GoRoute(path: '/orders',    builder: OrdersScreen),
      GoRoute(path: '/community', builder: CommunityScreen),
      GoRoute(path: '/profile',   builder: ProfileScreen),
    ],
  ),
];
```

---

## Phase 1 — Discovery & Design Foundation (Days 1–4)

### Goal
Set up the full project, implement the design system, and build all non-interactive structural components. No backend calls yet.

### Tasks

#### 1.1 Project Bootstrapping
- Run `flutter create lolipants --org com.lolipants --platforms android,ios`
- Add all dependencies to `pubspec.yaml` (see stack above)
- Set up `flutter_lints` and `very_good_analysis`
- Create the full folder structure as defined above
- Set up `.env` support using `flutter_dotenv` for `BETTER_AUTH_BASE_URL` and `CLOUDFLARE_API_BASE`
- Configure `android/app/build.gradle` for minSdk 24, targetSdk 34
- Configure iOS deployment target to 14.0

#### 1.2 Design System Implementation
- Implement `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius` exactly as specified above
- Implement `AppTheme` — dark theme only
- Implement bilingual string constants in `app_strings.dart`. Every user-facing string must have an English and Arabic version:
  ```dart
  class AppStrings {
    static const String appName     = 'Lolipants';
    static const String appNameAr   = 'لوليبانتس';
    static const String welcomeBack = 'Welcome back';
    static const String welcomeBackAr = 'مرحباً بعودتك';
    // ... all strings follow this pattern
  }
  ```

#### 1.3 Shared Widgets
Build these reusable components before any screens:

**LolipantsButton**
```dart
// Primary CTA — gold background, ink text
// Secondary — outlined gold border, gold text
// Destructive — outlined ruby border, ruby text
// All variants: full width, height 52, borderRadius AppRadius.md
// Loading state: replace label with CircularProgressIndicator (gold, size 20)
```

**LolipantsTextField**
```dart
// Background: AppColors.smoke
// Border: AppColors.borderSubtle, on focus: AppColors.gold
// Label floats above in AppColors.dust
// Error state: AppColors.rubyLight border + error text below
// Suffix/prefix icon support
// Obscure toggle for password fields
```

**ArabicEnglishLabel** — a widget that stacks an Arabic label above an English label
```dart
Widget build() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(arabicText, style: AppTextStyles.arabicLabel),
    Text(englishText, style: AppTextStyles.labelGold),
  ],
);
```

**GoldDivider** — thin horizontal rule in `AppColors.borderSubtle`

**LoadingOverlay** — full screen dark overlay with centred gold `CircularProgressIndicator`

#### 1.4 Arabesque Background Widget
This is a decorative SVG-pattern background used on multiple screens. Build it as a widget:
```dart
class ArabesqueBackground extends StatelessWidget {
  // Renders a hexagonal geometric tile pattern
  // Opacity: 0.03–0.05
  // Colour: AppColors.gold
  // Uses CustomPainter to draw repeating hexagonal lattice tiles
  // Covers the full screen, pointer events ignored
}
```

#### 1.5 Bottom Navigation Bar
```dart
class LolipantsBottomNavBar extends StatelessWidget {
  // 4 tabs: Home, Browse, Orders, Profile
  // Active tab icon + label in AppColors.gold
  // Inactive: AppColors.fog
  // Active indicator: small gold dot below label
  // Background: AppColors.ink
  // Top border: 1px AppColors.borderSubtle
  // Height: 64px including safe area
  // No elevation, no material shadow
}
```

---

## Phase 2 — Core App, Auth & Navigation (Days 5–10)

### Goal
Build and connect all auth screens, the main navigation shell, the home screen, and all category/section landing screens. All screens fully wired to Better Auth and router.

---

### Screen 1: Splash Screen

**File:** `features/splash/screens/splash_screen.dart`

**Behaviour:**
1. Show for minimum 2.5 seconds
2. On load, call `authProvider` to check existing session
3. If session exists → navigate to `/home`
4. If no session → navigate to `/onboarding` (first install) or `/login`
5. Track first install using SharedPreferences key `has_seen_onboarding`

**UI:**
- Background: `AppColors.ink`
- Full screen `ArabesqueBackground` at 0.04 opacity
- Centre: Lolipants logo (use placeholder asset until real logo provided)
- Below logo: Arabic brand name `لوليبانتس` in 22px gold, letter spacing 0.15
- Below Arabic: `LOLIPANTS` in 9px gold, letter spacing 0.22
- Thin gold divider (32px wide, 1px)
- Below: `wear your heritage` in 7.5px, `AppColors.fog`
- Loading indicator at bottom: 3 dots — active dot is 22px wide gold pill, inactive dots are 6px circles at 0.22 opacity
- Mascot animation placeholder: reserve a 130×160 space for Rive animation (add static panda image as placeholder)

**Animation sequence (implement with flutter_animate):**
1. Logo fades in (0ms → 600ms)
2. Arabic name slides up + fades in (400ms → 900ms)
3. Latin name fades in (700ms → 1000ms)
4. Divider expands from centre (900ms → 1200ms)
5. Tagline fades in (1100ms → 1400ms)

---

### Screen 2: Onboarding Screen

**File:** `features/onboarding/screens/onboarding_screen.dart`

**Behaviour:**
- 3 slides, swipeable with PageView
- Skip button top-right on slides 1 and 2
- "Get started" button on slide 3 → navigates to `/signup`
- On skip → navigate to `/login`
- After completion, set `has_seen_onboarding = true` in SharedPreferences

**Slides:**
1. **Design** — "Design your own fashion" / "صمم أزياءك الخاصة" — illustration of mannequin with gold garment
2. **Heritage** — "Inspired by your culture" / "مستوحى من ثقافتك" — illustration of arch/arabesque pattern
3. **Order** — "Made by expert tailors" / "مصنوع من قِبل خياطين خبراء" — illustration of tailor/garment delivery

**UI per slide:**
- Background: `AppColors.ink` + `ArabesqueBackground`
- Illustration area: top 55% of screen (use placeholder colored rectangles for now)
- Bottom card: `AppColors.stone`, rounded top corners `AppRadius.xl`
- Arabic title: `AppTextStyles.displayMedium`, gold
- English subtitle: `AppTextStyles.bodyLarge`, dust
- Page dots: 3 dots, active = gold pill 24px, inactive = circle 6px at 0.25 opacity
- Primary CTA button: `LolipantsButton` (primary variant)

---

### Screen 3: Sign Up Screen

**File:** `features/auth/screens/signup_screen.dart`

**Fields:**
- Full name
- Email address
- Password (obscured, toggle visibility)
- Confirm password (obscured, toggle visibility)

**Validation (all client-side before API call):**
- Name: required, min 2 chars
- Email: valid email format
- Password: min 8 chars, at least one number
- Confirm password: must match password

**Behaviour:**
1. On submit: validate → show `LoadingOverlay` → call `authRepository.signUp()`
2. On success: save session token → navigate to `/home` (replace, not push)
3. On error: show inline error banner below form (red background, error message from API)
4. "Already have an account? Log in" → navigate to `/login`

**UI:**
- Background: `AppColors.ink`
- Top: back chevron (left), "Create account" title (centre)
- Arabic subtitle: "إنشاء حساب" in `AppTextStyles.arabicLabel`
- Thin gold accent line below header (40px, centred)
- Form fields using `LolipantsTextField`
- 16px gap between fields
- `LolipantsButton` (primary) labelled "Create account / إنشاء حساب"
- Bottom: "Already have an account?" link → `/login`

---

### Screen 4: Log In Screen

**File:** `features/auth/screens/login_screen.dart`

**Fields:**
- Email address
- Password (obscured, toggle visibility)

**Validation:**
- Email: valid format
- Password: required, min 1 char (let API return the specific error)

**Behaviour:**
1. On submit: validate → `LoadingOverlay` → call `authRepository.signIn()`
2. On success: save session token → navigate to `/home` (replace)
3. On error: show error banner
4. "Forgot password?" → navigate to `/forgot`
5. "Don't have an account? Sign up" → navigate to `/signup`

**UI:**
- Same header pattern as signup
- Title: "Welcome back / مرحباً بعودتك"
- Below fields: "Forgot password?" right-aligned in `AppColors.gold`, 13px
- `LolipantsButton` (primary) labelled "Log in / تسجيل الدخول"

---

### Screen 5: Forgot Password Screen

**File:** `features/auth/screens/forgot_password_screen.dart`

**Fields:**
- Email address

**Behaviour:**
1. On submit: call `authRepository.forgotPassword(email)`
2. Show success state: replace form with confirmation message — "Check your email / تحقق من بريدك الإلكتروني"
3. "Back to login" button → navigate to `/login`

---

### Screen 6: Main Shell (Tab Navigator)

**File:** `features/shell/main_shell.dart`

**Behaviour:**
- ShellRoute wrapping 5 tab destinations
- `LolipantsBottomNavBar` at bottom
- Music mini-player appears above nav bar when music is playing (implement slot for it now, even if player not built yet — reserve 56px height)
- Each tab maintains its own navigation stack

**Tabs and icons (use custom SVG icons or Icon widget):**

| Tab | Label EN | Label AR | Icon |
|-----|----------|----------|------|
| Home | Home | الرئيسية | House outline |
| Browse | Browse | تصفح | Diamond outline |
| Orders | Orders | الطلبات | Document outline |
| Community | Community | المجتمع | People outline |
| Profile | Profile | الملف | Person circle outline |

---

### Screen 7: Home Screen

**File:** `features/home/screens/home_screen.dart`

**Sections (top to bottom):**

**Header bar:**
- Left: greeting "Good evening / مساء الخير" in `AppTextStyles.bodySmall` + user's name on next line in `AppTextStyles.titleLarge` with a gold `✦` character
- Right: circular avatar (initials, `AppColors.ember` bg, `AppColors.gold` border 1px, gold initials text)

**Hero banner card:**
- Background: `AppColors.stone`, border `AppColors.borderSubtle`, borderRadius `AppRadius.lg`
- Height: 88px
- Left side: text content — gold eyebrow label "AI DESIGNER · مصمم ذكي", title "Describe your dream outfit" in `AppTextStyles.titleSmall`, small gold CTA button "Try now →"
- Right side: decorative arch SVG with mannequin silhouette at 0.25 opacity

**Category pills (horizontal scroll, no scrollbar):**
Pills: All · Men رجال · Women نساء · Kids أطفال · Wedding · Accessories
Active pill: `AppColors.gold` background, `AppColors.ink` text
Inactive pill: `AppColors.borderSubtle` border, `AppColors.fog` text

**"Traditional styles" section:**
- Section header row: title left, "See all" right (gold, tappable → `/browse`)
- 2-column grid of style cards (see StyleCard widget below)

**StyleCard widget:**
```dart
// Image area: 58px height, coloured background per region
// Body: garment name in titleSmall, origin/count in bodySmall
// Border: borderSubtle, borderRadius: AppRadius.md
// On tap: navigate to category detail screen (route TBD in Phase 3)
```

**Data for home screen:** hardcode 4 style cards for now:
- Qatari Thobe (deep purple bg)
- Saudi Bisht (forest green bg)
- UAE Kandura (gold bg)
- Omani Dishdasha (teal bg)

**ArabesqueBackground** at 0.03 opacity behind everything.

---

### Screen 8: Browse Screen (stub)

**File:** `features/browse/screens/browse_screen.dart`

Phase 2 stub only. Show:
- Header: "الأزياء التقليدية / Traditional styles"
- Region tabs: Gulf · Modern · Levant (use same pill style as home)
- 2×2 grid of country cards (Qatar, Saudi Arabia, UAE, Oman) — same arch silhouette design from UI mockup
- Each card: coloured header area with arch SVG, country name, garment types listed below
- Featured strip at bottom: gold-bordered card reading "Hand-embroidered Jalabiya · Gulf collection"
- Full wiring to category detail screens deferred to Phase 3

---

### Screen 9: Orders Screen (stub)

**File:** `features/orders/screens/orders_screen.dart`

Phase 2 stub only. Show:
- Header: "My orders / طلباتي"
- Empty state if no orders: gold diamond icon + "No orders yet / لا توجد طلبات بعد" + "Start designing" button → `/home`
- Full order list and detail wired in Phase 5

---

### Screen 10: Community Screen (stub)

**File:** `features/community/screens/community_screen.dart`

Phase 2 stub only. Show:
- Header: "Community / المجتمع"
- Placeholder cards for: News Feed, Designer Showcase, Consultations
- Full wiring deferred to Phase 4

---

### Screen 11: Profile Screen (stub)

**File:** `features/profile/screens/profile_screen.dart`

Phase 2 stub only. Show:
- Avatar circle (large, 80px, initials)
- User name + email from auth state
- List tiles: My Designs · My Measurements · Notifications · Settings · Log Out
- Log Out calls `authRepository.signOut()` → navigates to `/login` (replace all)
- Full settings and edit profile deferred to later phase

---

## API Layer Setup

Set up the Dio client now even though most endpoints are not used until Phase 3+.

```dart
// dio_client.dart
class DioClient {
  static Dio create() {
    final dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(AuthInterceptor());   // attaches session token to every request
    dio.interceptors.add(LogInterceptor());     // debug logging in dev mode only
    dio.interceptors.add(ErrorInterceptor());   // maps HTTP errors to typed AppException

    return dio;
  }
}

// AuthInterceptor reads token from flutter_secure_storage and adds:
// headers['Authorization'] = 'Bearer $token'
// On 401 response: clear token, redirect to /login
```

---

## Error Handling

Define a sealed class for app errors used throughout:

```dart
sealed class AppException {
  const AppException();
}

class NetworkException extends AppException {
  final String message;
}

class AuthException extends AppException {
  final String message;  // "invalid_credentials" | "email_taken" | "session_expired"
}

class ServerException extends AppException {
  final int statusCode;
  final String message;
}

class UnknownException extends AppException {}
```

All repository methods return `Either<AppException, T>` using the `fpdart` package, or use a `Result` pattern. Do not use raw try/catch in UI layer.

---

## Environment Variables

Create a `.env` file at project root (add to `.gitignore`):

```env
BETTER_AUTH_BASE_URL=https://your-better-auth-instance.com
API_BASE_URL=https://your-cloudflare-worker.com/api
CLOUDFLARE_R2_BASE_URL=https://your-r2-bucket.com
```

Load with `flutter_dotenv` in `main.dart` before `runApp`.

---

## Localisation

For Phase 1–2, handle bilingual display manually using the `AppStrings` constants class. Do not set up full `flutter_localizations` intl yet — that comes in a later phase. For now:

- All screens must display both Arabic and English labels as shown in the UI mockup
- Arabic text always uses `Noto Naskh Arabic` font
- Do not force RTL layout yet — Phase 3+ will handle full RTL support
- Wrap Arabic text in `Directionality(textDirection: TextDirection.rtl, child: ...)` where needed

---

## Assets

Add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/animations/    # Rive mascot files (add placeholder)
    - assets/images/
    - .env
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
        - asset: assets/fonts/Poppins-Medium.ttf  weight: 500
    - family: NotoNaskhArabic
      fonts:
        - asset: assets/fonts/NotoNaskhArabic-Regular.ttf
        - asset: assets/fonts/NotoNaskhArabic-Medium.ttf  weight: 500
```

Download Poppins and Noto Naskh Arabic from Google Fonts and place in `assets/fonts/`.

---

## Code Quality Rules

Follow these rules on every file:

1. No `print()` statements — use a logger (dart's `logging` package)
2. No hard-coded strings in widget files — all strings from `AppStrings`
3. No hard-coded colours in widget files — all from `AppColors`
4. No business logic in widget `build()` methods — extract to providers or use-cases
5. Every public class and method must have a doc comment
6. Widget files contain only one primary widget class
7. Keep widget build methods under 80 lines — extract sub-widgets aggressively
8. All `async` calls must handle loading and error states — never show a blank screen

---

## pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management & routing
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.0.0

  # Network
  dio: ^5.4.3
  flutter_dotenv: ^5.1.0

  # Auth & storage
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.2

  # Functional programming / error handling
  fpdart: ^1.1.0

  # UI & animations
  flutter_animate: ^4.5.0
  rive: ^0.13.2
  google_fonts: ^6.2.1

  # Utilities
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  very_good_analysis: ^6.0.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3
```

---

## What NOT to Build in Phase 1–2

Do not start on any of the following — they belong to later phases:

- 3D mannequin or design editor (Phase 3)
- Fabric selectors or design tools (Phase 3)
- AI assistant integration (Phase 3)
- Body measurement / sizing system (Phase 3)
- News feed or community features (Phase 4)
- Tap Payments integration (Phase 5)
- GPS delivery tracking (Phase 5)
- Tailor dashboard (Phase 5)
- Admin panel (Phase 5)
- Full RTL localisation (Phase 3+)
- Push notifications (Phase 5)

---

## Definition of Done — Phase 1

- [ ] Project runs on Android emulator and iOS simulator without errors
- [ ] Design system fully implemented and all shared widgets built
- [ ] Splash screen animates correctly and routes based on session state
- [ ] Onboarding slides swipeable, skip and get-started buttons navigate correctly
- [ ] `has_seen_onboarding` flag persists across cold starts

## Definition of Done — Phase 2

- [ ] Sign up creates a user via Better Auth and stores session token securely
- [ ] Log in authenticates and stores session token
- [ ] Forgot password sends reset email
- [ ] Route guard redirects unauthenticated users to `/login` on any protected route
- [ ] Route guard redirects authenticated users away from `/login` and `/signup`
- [ ] Bottom nav tab switching works with independent stack per tab
- [ ] Home screen renders all sections with hardcoded data
- [ ] Browse, Orders, Community, Profile stubs render without errors
- [ ] Log out clears token and navigates to `/login`
- [ ] All screens display both Arabic and English labels
- [ ] No Firebase or Google Auth SDK anywhere in the project

---

*End of Phase 1–2 instructions. Phase 3 (3D Editor, AI & Sizing) instructions will be provided separately.*
