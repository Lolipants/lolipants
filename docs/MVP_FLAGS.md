# Design → Order MVP (compile-time flags)

The customer app can be built with a slimmer surface to validate **mannequin → editor → checkout → fulfilment** before shipping community, music chrome, or the editor AI tab.

## `dart-define` flags

| Define | Default (debug) | When `false` |
|--------|-----------------|---------------|
| `FEATURE_COMMUNITY` | `true` | Hides the Community shell tab (branch index 3); redirects `/community/*` to `/home`; hides designer earnings & consultations rows on Profile. |
| `FEATURE_MUSIC_PLAYER` | `true` | Hides the music mini-player strip above the bottom nav. |
| `FEATURE_AI_EDITOR_TAB` | `true` | Hides the editor bottom-panel **AI** tab; choosing AI coerces to **Fabric** in [EditorNotifier.setTab](lib/features/editor/providers/editor_provider.dart). |
| `FEATURE_MENS` | `true` | Hides men/kids category-mannequin entry points and forces women-only MVP browse/editor defaults. |
| `FEATURE_FINAL_RENDER_PREVIEW` | `true` | Skips final Meshy render preview surfaces and keeps checkout flow on editor preview only. |

Implementation: [lib/core/config/app_features.dart](lib/core/config/app_features.dart).

## Example release build

```bash
flutter build apk \
  --dart-define=FEATURE_COMMUNITY=false \
  --dart-define=FEATURE_MUSIC_PLAYER=false \
  --dart-define=FEATURE_AI_EDITOR_TAB=false \
  --dart-define=FEATURE_MENS=false \
  --dart-define=FEATURE_FINAL_RENDER_PREVIEW=false
```

No server changes are required for the MVP client; API routes may remain enabled.

## Canonical MVP release profile

Use this single command template for all MVP mobile release builds:

```bash
flutter build appbundle --release \
  --dart-define=FEATURE_COMMUNITY=false \
  --dart-define=FEATURE_MUSIC_PLAYER=false \
  --dart-define=FEATURE_AI_EDITOR_TAB=false \
  --dart-define=FEATURE_MENS=false \
  --dart-define=FEATURE_FINAL_RENDER_PREVIEW=false
```
