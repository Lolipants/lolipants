/// Compile-time feature flags for MVP vs full app builds.
///
/// Release MVP builds should pass:
/// `--dart-define=FEATURE_COMMUNITY=false`
/// `--dart-define=FEATURE_MUSIC_PLAYER=false`
/// `--dart-define=FEATURE_AI_EDITOR_TAB=false`
/// `--dart-define=FEATURE_MENS=false` (women-first MVP: hide men/kids browse
/// entries and non-women mannequin defaults in the editor)
/// `--dart-define=FEATURE_CASUAL=false` (hide Casual browse lane + presets)
///
/// Debug defaults stay `true` so developers see the full surface unless they
/// opt into the slim MVP preview.

/// Community tab, `/community/*` routes, and profile links to community.
const bool kFeatureCommunity = bool.fromEnvironment(
  'FEATURE_COMMUNITY',
  defaultValue: true,
);

/// Music mini-player strip above the bottom nav.
const bool kFeatureMusicPlayer = bool.fromEnvironment(
  'FEATURE_MUSIC_PLAYER',
  defaultValue: true,
);

/// Editor bottom-panel AI tab (paired with Designs only; no legacy fabric /
/// pattern / embroidery / text tabs in the shell).
const bool kFeatureAiEditorTab = bool.fromEnvironment(
  'FEATURE_AI_EDITOR_TAB',
  defaultValue: true,
);

/// Non-women catalogue/mannequin surfaces (men + kids category paths and
/// non-women mannequin options).
///
/// Set to `false` for a women-first MVP export.
const bool kFeatureMens = bool.fromEnvironment(
  'FEATURE_MENS',
  defaultValue: true,
);

/// Casual lane (T-shirts, polos, etc.) in browse/home and editor catalogue filter.
const bool kFeatureCasual = bool.fromEnvironment(
  'FEATURE_CASUAL',
  defaultValue: true,
);

/// Editor **Build** tab: modular slot/option configurator (Design yourself).
const bool kFeatureConfiguratorBuild = bool.fromEnvironment(
  'FEATURE_CONFIGURATOR_BUILD',
  defaultValue: true,
);

/// Standalone wedding dress catalogue + checkout flow.
const bool kFeatureWeddingFlow = bool.fromEnvironment(
  'FEATURE_WEDDING_TAB',
  defaultValue: true,
);

/// @deprecated Use [kFeatureWeddingFlow]. Kept for existing build flags.
const bool kFeatureWeddingTab = kFeatureWeddingFlow;

/// Accessories browse shop, standalone checkout, and editor garment add-ons.
const bool kFeatureAccessories = bool.fromEnvironment(
  'FEATURE_ACCESSORIES',
  defaultValue: true,
);

/// "Use my photo" custom mannequin generation.
///
/// Disabled by default in low-cost mode because it needs a paid backend job.
const bool kFeatureCustomPhotoMannequin = bool.fromEnvironment(
  'FEATURE_CUSTOM_PHOTO_MANNEQUIN',
  defaultValue: false,
);

/// Admin CMS create/edit/upload for mannequins (v1 uses bundled catalog only).
const bool kFeatureAdminMannequinCms = bool.fromEnvironment(
  'FEATURE_ADMIN_MANNEQUIN_CMS',
  defaultValue: false,
);

/// Payment mode switch for internal review builds.
///
/// When enabled, checkout uses a mock/sandbox confirmation path and shows
/// explicit "no real charge" copy.
const bool kFeatureMockPayment = bool.fromEnvironment(
  'FEATURE_MOCK_PAYMENT',
  defaultValue: false,
);

/// [StatefulNavigationShell] branch index for Home. Must match shell ordering.
const int kHomeShellBranchIndex = 0;

/// [StatefulNavigationShell] branch index for Community when
/// [kFeatureCommunity] is true (0=home, 1=browse, 2=orders, 3=community,
/// 4=profile). Must match [LolipantsBottomNavBar] ordering.
const int kCommunityShellBranchIndex = 3;
