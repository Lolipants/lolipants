/// Compile-time feature flags for MVP vs full app builds.
///
/// Release MVP builds should pass:
/// `--dart-define=FEATURE_COMMUNITY=false`
/// `--dart-define=FEATURE_MUSIC_PLAYER=false`
/// `--dart-define=FEATURE_AI_EDITOR_TAB=false`
/// `--dart-define=FEATURE_MENS=false` (women-first MVP: hide men/kids browse
/// entries and non-women mannequin defaults in the editor)
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

/// Editor bottom-panel "AI" tab ([EditorTab.ai]).
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

/// Final render preview screen that fetches server-rendered artifacts.
///
/// Keep enabled in dev, but allow MVP builds to disable Meshy/preview surfaces.
const bool kFeatureFinalRenderPreview = bool.fromEnvironment(
  'FEATURE_FINAL_RENDER_PREVIEW',
  defaultValue: true,
);

/// [StatefulNavigationShell] branch index for Community when
/// [kFeatureCommunity] is true (0=home, 1=browse, 2=orders, 3=community,
/// 4=profile). Must match [LolipantsBottomNavBar] ordering.
const int kCommunityShellBranchIndex = 3;
