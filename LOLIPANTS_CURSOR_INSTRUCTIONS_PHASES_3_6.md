# Lolipants — Cursor Development Instructions: Phases 3–6

## Context

This document continues from `LOLIPANTS_CURSOR_INSTRUCTIONS.md` which covers Phases 1 and 2.
**Phases 1 and 2 must be fully complete and all Definition of Done checkboxes ticked before starting any work here.**

The tech stack, design system, `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, `AppStrings`, shared widgets, auth layer, `DioClient`, error handling, and `OrderStatus` model are all already established. Do not redefine them here — extend and build on top of them.

Refer to the Phase 1–2 document for all constants, colours, and widget specifications.

---

## New Folders Added by Phases 3–6

Add the following to the existing project structure:

```
lib/features/
├── editor/
│   ├── screens/
│   │   └── editor_screen.dart
│   ├── widgets/
│   │   ├── mannequin_viewer.dart
│   │   ├── tool_rail.dart
│   │   ├── colour_strip.dart
│   │   ├── editor_bottom_panel.dart
│   │   ├── fabric_selector.dart
│   │   ├── text_tool_panel.dart
│   │   ├── image_print_panel.dart
│   │   ├── ai_prompt_bar.dart
│   │   └── design_preview_360.dart
│   ├── models/
│   │   ├── garment_design.dart
│   │   ├── fabric_option.dart
│   │   └── design_text_layer.dart
│   ├── data/
│   │   ├── editor_repository.dart
│   │   └── designs_repository.dart
│   └── providers/
│       ├── editor_provider.dart
│       └── designs_provider.dart
├── sizing/
│   ├── screens/
│   │   ├── sizing_method_screen.dart
│   │   ├── ai_measurement_screen.dart
│   │   ├── manual_size_screen.dart
│   │   └── workshop_booking_screen.dart
│   ├── models/
│   │   └── body_measurements.dart
│   └── providers/
│       └── sizing_provider.dart
├── browse/
│   └── screens/
│       ├── category_detail_screen.dart
│       ├── garment_style_screen.dart
│       └── mannequin_selector_screen.dart
├── community/
│   ├── screens/
│   │   ├── news_feed_screen.dart
│   │   ├── post_detail_screen.dart
│   │   ├── create_post_screen.dart
│   │   ├── showcase_screen.dart
│   │   ├── designer_profile_screen.dart
│   │   ├── pro_designers_screen.dart
│   │   └── consultation_screen.dart
│   ├── models/
│   │   ├── post.dart
│   │   ├── designer.dart
│   │   └── consultation_request.dart
│   ├── data/
│   │   └── community_repository.dart
│   └── providers/
│       └── community_provider.dart
├── orders/
│   └── screens/
│       ├── order_summary_screen.dart
│       ├── size_confirmation_screen.dart
│       ├── delivery_details_screen.dart
│       ├── payment_screen.dart
│       └── order_confirmation_screen.dart
│   └── data/
│       └── orders_repository.dart
│   └── providers/
│       └── orders_provider.dart
├── music/
│   ├── widgets/
│   │   ├── music_mini_player.dart
│   │   └── music_expanded_player.dart
│   └── providers/
│       └── music_provider.dart
└── profile/
    └── screens/
        ├── edit_profile_screen.dart
        ├── my_designs_screen.dart
        ├── my_measurements_screen.dart
        └── settings_screen.dart
```

---

## New Routes to Add (extend `app_router.dart`)

```dart
// Editor
GoRoute(path: '/editor',              builder: EditorScreen),
GoRoute(path: '/editor/preview',      builder: DesignPreview360Screen),

// Sizing
GoRoute(path: '/sizing',              builder: SizingMethodScreen),
GoRoute(path: '/sizing/ai',           builder: AiMeasurementScreen),
GoRoute(path: '/sizing/manual',       builder: ManualSizeScreen),
GoRoute(path: '/sizing/workshop',     builder: WorkshopBookingScreen),

// Browse detail
GoRoute(path: '/browse/:category',    builder: CategoryDetailScreen),
GoRoute(path: '/browse/style/:id',    builder: GarmentStyleScreen),
GoRoute(path: '/mannequin-selector',  builder: MannequinSelectorScreen),

// Community
GoRoute(path: '/community/feed',      builder: NewsFeedScreen),
GoRoute(path: '/community/feed/:id',  builder: PostDetailScreen),
GoRoute(path: '/community/post/new',  builder: CreatePostScreen),
GoRoute(path: '/community/showcase',  builder: ShowcaseScreen),
GoRoute(path: '/community/designer/:id', builder: DesignerProfileScreen),
GoRoute(path: '/community/pros',      builder: ProDesignersScreen),
GoRoute(path: '/community/consult',   builder: ConsultationScreen),

// Order flow
GoRoute(path: '/order/summary',       builder: OrderSummaryScreen),
GoRoute(path: '/order/size-confirm',  builder: SizeConfirmationScreen),
GoRoute(path: '/order/delivery',      builder: DeliveryDetailsScreen),
GoRoute(path: '/order/payment',       builder: PaymentScreen),
GoRoute(path: '/order/confirmed',     builder: OrderConfirmationScreen),
GoRoute(path: '/orders/:id',          builder: OrderDetailScreen),  // already exists, keep

// Profile extras
GoRoute(path: '/profile/edit',        builder: EditProfileScreen),
GoRoute(path: '/profile/designs',     builder: MyDesignsScreen),
GoRoute(path: '/profile/measurements',builder: MyMeasurementsScreen),
GoRoute(path: '/profile/settings',    builder: SettingsScreen),
```

---

## New `AppStrings` to Add

Add these to the existing `app_strings.dart`:

```dart
// Editor
static const String designEditor     = 'Design editor';
static const String designEditorAr   = 'محرر التصميم';
static const String selectFabric     = 'Select fabric';
static const String selectFabricAr   = 'اختر القماش';
static const String selectColour     = 'Select colour';
static const String selectColourAr   = 'اختر اللون';
static const String addText          = 'Add text';
static const String addTextAr        = 'إضافة نص';
static const String addImage         = 'Add image';
static const String addImageAr       = 'إضافة صورة';
static const String aiPromptHint     = 'Describe a design…';
static const String aiPromptHintAr   = 'صف التصميم المطلوب…';
static const String saveDesign       = 'Save design';
static const String saveDesignAr     = 'حفظ التصميم';
static const String previewDesign    = 'Preview 360°';
static const String previewDesignAr  = 'معاينة 360°';
static const String embroidery       = 'Embroidery';
static const String embroideryAr     = 'تطريز';
static const String pattern          = 'Pattern';
static const String patternAr        = 'نمط';

// Sizing
static const String chooseSizingMethod   = 'How would you like to be measured?';
static const String chooseSizingMethodAr = 'كيف تريد أخذ مقاساتك؟';
static const String aiMeasurement        = 'AI measurement';
static const String aiMeasurementAr      = 'قياس ذكي';
static const String manualEntry          = 'Enter manually';
static const String manualEntryAr        = 'إدخال يدوي';
static const String workshopVisit        = 'Visit workshop';
static const String workshopVisitAr      = 'زيارة الورشة';
static const String myMeasurements       = 'My measurements';
static const String myMeasurementsAr     = 'مقاساتي';

// Community
static const String fashionNews          = 'Fashion news';
static const String fashionNewsAr        = 'أخبار الموضة';
static const String designerShowcase     = 'Designer showcase';
static const String designerShowcaseAr   = 'معرض المصممين';
static const String consultations        = 'Consultations';
static const String consultationsAr      = 'الاستشارات';
static const String createPost           = 'Create post';
static const String createPostAr         = 'إنشاء منشور';
static const String proDesigners         = 'Pro designers';
static const String proDesignersAr       = 'مصممون محترفون';

// Orders & payment
static const String orderSummary         = 'Order summary';
static const String orderSummaryAr       = 'ملخص الطلب';
static const String confirmSize          = 'Confirm size';
static const String confirmSizeAr        = 'تأكيد المقاس';
static const String deliveryDetails      = 'Delivery details';
static const String deliveryDetailsAr    = 'تفاصيل التوصيل';
static const String payment              = 'Payment';
static const String paymentAr            = 'الدفع';
static const String placeOrder           = 'Place order';
static const String placeOrderAr         = 'تقديم الطلب';
static const String orderPlaced          = 'Order placed!';
static const String orderPlacedAr        = 'تم تقديم الطلب!';
static const String continueShopping     = 'Continue designing';
static const String continueShoppingAr   = 'متابعة التصميم';
static const String address              = 'Delivery address';
static const String addressAr            = 'عنوان التوصيل';
static const String phone                = 'Phone number';
static const String phoneAr              = 'رقم الهاتف';
```

---

---

# PHASE 3 — 3D Design Editor, AI & Sizing System
### Days 11–20 · Complete all of Phase 2 before starting

---

## Phase 3 goal
Deliver the full design editor: mannequin selection, garment customisation, fabric/colour/quality pickers, custom text and image printing, AI design assistant, and the complete three-path sizing system. This is the core product feature and the most complex phase.

---

# PHASE 3A — Mannequin & Editor Shell
### Days 11–13

## Goal
Build the editor screen shell, mannequin viewer, tool rail, colour strip, and the bottom panel tab structure. No AI or sizing yet — just the visual editor working end-to-end with fabric and colour changes reflected on the mannequin.

---

## 3A.1 — Garment Design Model

```dart
// editor/models/garment_design.dart
class GarmentDesign {
  final String id;
  final String name;
  final String garmentType;    // 'thobe' | 'abaya' | 'bisht' | 'kandura' | 'dress' | 'suit' | ...
  final String fabricId;
  final String fabricQuality;  // 'standard' | 'premium' | 'suit_grade'
  final Color primaryColour;
  final Color? accentColour;
  final String? patternId;
  final List<DesignTextLayer> textLayers;
  final String? printImagePath;   // R2 URL of uploaded image
  final String? presetStyleId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class DesignTextLayer {
  final String id;
  final String text;
  final String fontFamily;
  final double fontSize;
  final Color colour;
  final Offset placement;      // normalised 0.0–1.0 relative to mannequin bounds
  final double rotation;
}
```

```dart
// editor/models/fabric_option.dart
class FabricOption {
  final String id;
  final String name;           // 'Silk' | 'Linen' | 'Cotton' | 'Crepe' | 'Chiffon' | ...
  final String nameAr;
  final String quality;        // 'standard' | 'premium' | 'suit_grade'
  final String garmentType;    // which garment type this fabric applies to
  final bool isAvailable;
}
```

---

## 3A.2 — Mannequin Selector Screen

**File:** `browse/screens/mannequin_selector_screen.dart`

Accessed from the editor or from browse — user picks a body shape before entering the design editor.

**Body shape options (temporary seed list for Phase 3 UI only):**

> **Reminder (backend/admin):** mannequin options must be sourced from the admin dashboard data model/API as soon as admin tooling is available. Do not keep this list hardcoded beyond initial Phase 3 prototyping.

| ID | Label EN | Label AR |
|---|---|---|
| `standard_female` | Standard (Female) | نسائي قياسي |
| `curvy_female` | Curvy (Female) | نسائي ممتلئ |
| `petite_female` | Petite (Female) | نسائي قصير |
| `standard_male` | Standard (Male) | رجالي قياسي |
| `tall_male` | Tall (Male) | رجالي طويل |
| `child` | Child | أطفال |
| `custom_photo` | Use my photo | استخدم صورتي |

**UI:**
- Header: "Choose your mannequin / اختر المانيكان"
- Horizontal scroll row of mannequin silhouette cards (80×140px each)
- Each card: `AppColors.stone` bg, arch SVG mannequin silhouette, label below
- Active card: `AppColors.borderStrong` border 2px, gold label
- "Use my photo" card: dashed `borderDefault` border, camera icon, gold label
  - On tap: trigger `image_picker` to select from gallery or camera
  - On image selected: show crop/confirm screen (simple `Container` with image, Confirm CTA)
  - Confirmed image stored in `editorProvider` as `customMannequinImagePath`
- Bottom CTA: `LolipantsButton(primary)` "Start designing / ابدأ التصميم" → `/editor` with selected mannequin passed as route extra

---

## 3A.3 — Editor Screen Shell

**File:** `editor/screens/editor_screen.dart`

**Overall layout:**
```dart
Scaffold(
  body: Stack(
    children: [
      ArabesqueBackground(opacity: 0.03),
      Column(
        children: [
          EditorTopBar(),         // back, title, save button
          Expanded(
            child: MannequinViewer(),   // centre stage — mannequin + tool overlays
          ),
          EditorBottomPanel(),    // tab panel: Fabric | Pattern | Embroidery | Text | AI
        ],
      ),
    ],
  ),
)
```

**EditorTopBar** (`editor/widgets/editor_top_bar.dart`)
- Left: back chevron → show `AlertDialog` "Exit without saving? / الخروج بدون حفظ؟" (Cancel + Exit)
- Centre: "Design editor / محرر التصميم" (`titleSmall`, sand)
- Right: `LolipantsButton(primary)` at 32px height "Save / حفظ"
  - On tap: call `editorProvider.saveDesign()` → on success show snack bar "Design saved / تم الحفظ" → pop

---

## 3A.4 — Mannequin Viewer

**File:** `editor/widgets/mannequin_viewer.dart`

This is the centrepiece of the editor. Renders the mannequin with the current design applied.

**Mannequin rendering approach:**
- Use Flutter `CustomPainter` for Phase 3 — draw SVG-based mannequin paths in Dart
- Each garment is composed of named regions (body, sleeves, skirt/lower, collar, hem)
- Apply `primaryColour` to the main body region, `accentColour` to collar and hem
- Overlay `DesignTextLayer` widgets positioned using `Positioned` within a `Stack`
- If `printImagePath` is set, render it as a constrained `Image.network` overlaid on the torso region

**Mannequin paths per garment type (implement these `CustomPainter` shapes):**

`abaya`:
- Head: ellipse
- Hijab: curved path over head + side drape
- Body: trapezoidal torso path
- Sleeves: rounded rectangles left and right
- Skirt: flared lower path to screen bottom
- Hem: 3 horizontal decoration lines near bottom

`thobe`:
- Head: ellipse
- Neck: short rect
- Body: straight-sided robe from shoulder to ankle
- Collar: V-notch at top
- Sleeves: full-length straight
- Centre seam: single vertical line
- Cuffs: horizontal accent lines at wrist

`bisht`:
- Rendered as a layered `thobe` underneath + open-front cloak overlay
- Cloak fill at 60% opacity of `primaryColour`
- Gold diagonal stripe pattern painted across cloak

`kandura`:
- Same shape as `thobe` but shorter (mid-calf)
- No visible seam
- Collar: round neck

`suit`:
- Jacket body with lapels
- Trouser legs below
- Tie/accessory region on chest

For garment types not listed, use the `thobe` shape as fallback.

**Interaction:**
- `GestureDetector` wrapping the viewer:
  - On text layer tap: select it → highlight with `AppColors.gold` dashed border
  - On text layer drag: update `placement` in `editorProvider`
- Pinch-to-zoom on the entire viewer (use `InteractiveViewer`, min scale 0.8, max 2.5)

**ToolRail** (`editor/widgets/tool_rail.dart`)
- Positioned `left: 8`, vertically centred
- 4 icon buttons:
  - Colour picker (circle icon) — active state: `AppColors.gold` tinted bg
  - Text tool (T icon)
  - Image print tool (image icon)
  - Ruler / sizing shortcut (ruler icon) → navigates to `/sizing`
- Active tool stored in `editorProvider.activeTool`
- Each button: 28×28px, `AppColors.stone`, `AppRadius.md`, `borderSubtle` 1px

**ColourStrip** (`editor/widgets/colour_strip.dart`)
- Positioned `right: 8`, vertically centred
- 6 colour swatches (circles, 18px) in a `Column`
- Default swatches: teal `#162F28`, gold, deep purple `#1A1040`, ruby `#6B1A1A`, sand, ink
- Selected swatch: 1.5px `AppColors.gold` ring
- On tap: update `editorProvider.primaryColour`
- Last swatch: `+` icon → open full colour picker (`showModalBottomSheet` with a `ColorPicker` widget — use `flutter_colorpicker` package)

---

## 3A.5 — Editor Bottom Panel

**File:** `editor/widgets/editor_bottom_panel.dart`

- `Container`: `AppColors.stone`, `BorderRadius.vertical(top: AppRadius.lg)`, `borderStrong` top border 1px
- Tab row: Fabric · Pattern · Embroidery · Text · AI
  - Active tab: `AppColors.gold` text + 1.5px gold underline
  - Inactive: `AppColors.fog`
- Tab content switches based on `editorProvider.activeTab`

**Fabric tab (`editor/widgets/fabric_selector.dart`):**
- Horizontal scroll of `FabricChip` widgets
- Each chip: label text, `AppColors.smoke` bg, `borderSubtle` border
- Selected: `borderDefault` border, gold text, `AppColors.stone` bg
- Fabrics are loaded from `editorProvider.availableFabrics` (fetched per garment type from API)
- Below fabric chips: quality row — 3 chips: Standard · Premium · Suit-grade
  - Selected quality chip: gold bg, ink text

**Pattern tab:**
- Grid of pattern thumbnail cards (64×64px)
- Patterns fetched from API (`GET /patterns?garmentType=abaya`)
- Tapping a pattern applies it as an overlay on the mannequin (CSS-style repeat paint)
- For Phase 3: hardcode 6 pattern options (geometric, stripe, plain, arabesque, floral, embroidered)

**Embroidery tab:**
- Same grid layout as patterns but for embroidery overlays
- Tapping places a gold embroidery SVG overlay at collar or hem (two placement options shown as radio buttons)
- Hardcode 4 embroidery motifs for Phase 3

**Text tab:** → see Phase 3B

**AI tab:** → see Phase 3C

---

## 3A Definition of Done

- [ ] `MannequinSelectorScreen` renders all body shape options, photo upload works
- [ ] `EditorScreen` opens with selected mannequin shape rendered via `CustomPainter`
- [ ] `primaryColour` changes reflect live on mannequin body
- [ ] `ColourStrip` swatch selection updates mannequin colour
- [ ] Full colour picker modal opens and applies colour
- [ ] Fabric chips load per garment type and selection updates `editorProvider`
- [ ] Quality chips (Standard / Premium / Suit-grade) switch correctly
- [ ] Pattern and Embroidery tabs render hardcoded options
- [ ] Back button shows exit confirmation dialog
- [ ] Save button calls `editorProvider.saveDesign()` and shows feedback

---

# PHASE 3B — Text Tool, Image Printing & Design Gallery
### Days 14–16

## Goal
Complete the custom text-on-garment feature, the image print-on-garment feature, the design save flow, and the 360° preview. Wire designs to the backend (Cloudflare D1 + R2).

---

## 3B.1 — Text Tool Panel

**File:** `editor/widgets/text_tool_panel.dart`

Appears as `EditorBottomPanel` content when Text tab is active.

**Sections (stacked vertically inside a scrollable panel):**

**Text input row:**
- `LolipantsTextField` with hint "Type your text / اكتب نصك" (single line)
- "Add to design" CTA pill button → creates a new `DesignTextLayer` at centre of mannequin

**Font selector:**
- Horizontal scroll of font preview chips showing the font name in that font
- Available fonts: Poppins · Noto Naskh Arabic · Playfair Display · Roboto Mono · Dancing Script · Amiri
- Selected font: gold border
- On select: update the active text layer's `fontFamily`

**Size slider:**
- `Slider`, min 12, max 48, divisions 36, step 1
- Label shows current size
- On change: update active layer `fontSize`

**Colour row:**
- Row of 8 colour swatches (same swatch design as `ColourStrip`)
- On tap: update active layer `colour`

**Placement instruction:**
- `Text`: "Drag the text on the garment to reposition / اسحب النص على الملبس لتغيير موضعه"
- `bodySmall`, `AppColors.dust`

**Delete layer button:**
- Only visible when a layer is selected
- `LolipantsButton(destructive)` "Remove text / حذف النص"

---

## 3B.2 — Image Print Panel

**File:** `editor/widgets/image_print_panel.dart`

Appears as overlay panel when Image Print tool is selected from `ToolRail`.

**UI:**
- Title: "Print on garment / طباعة على الملبس"
- Upload area: dashed border `borderDefault`, 120×120px centred, upload icon + "Upload image / ارفع صورة"
  - On tap: `image_picker` (gallery or camera)
  - On image selected: show small preview + file name
- Placement selector: 3 radio options — Chest · Back · Full front
- Size slider: percentage of garment width (20%–80%), step 5
- "Apply to design" CTA pill → upload image to Cloudflare R2 via `editorProvider.uploadPrintImage()`, set `printImagePath` on design, render on mannequin

---

## 3B.3 — Save Design Flow

**File:** `editor/providers/editor_provider.dart`

`saveDesign()` method:
1. Validate design has a name (prompt user with `showDialog` text input if name is empty)
2. Upload any local `printImagePath` to R2 if not already uploaded
3. `POST /designs` with full `GarmentDesign` JSON body
4. On success: add to `designsProvider` local list, show snack bar, optionally pop editor

**Design name dialog:**
```dart
// showDialog with a LolipantsTextField for the design name
// Confirm: "Save / حفظ" → proceeds to save
// Cancel: returns to editor
```

---

## 3B.4 — 360° Preview Screen

**File:** `editor/screens/design_preview_360.dart`

- Full screen dark background (`AppColors.ink`)
- `ArabesqueBackground` at 0.03 opacity
- Centre: `AnimatedBuilder` that rotates the mannequin `CustomPainter` around Y axis
  - Use `Transform` with `Matrix4.rotationY(angle)` — simulate 3D rotation with perspective
  - `AnimationController`, duration 4 seconds, repeat
- Bottom row: 3 action buttons
  - Share (secondary outline) — Phase 6
  - Order this design (primary, gold) → navigates to `/order/summary` with design as extra
  - Back to editor (secondary outline) → pop
- Top: back chevron to return to editor

---

## 3B.5 — My Designs Screen

**File:** `profile/screens/my_designs_screen.dart`

- Header: "My designs / تصاميمي"
- `GridView.count(crossAxisCount: 2)` of `DesignThumbnailCard` widgets
- `DesignThumbnailCard`: 
  - 140px tall, `AppColors.stone` bg
  - Mannequin thumbnail (miniature `CustomPainter` at 0.4 scale)
  - Design name below in `titleSmall`
  - Date in `bodySmall`, dust
  - Long press → `showModalBottomSheet` with: Edit · Order · Delete options
- Empty state: gold star icon + "No designs saved yet / لم تحفظ أي تصميم بعد" + "Create your first design" CTA → `/mannequin-selector`
- Pull-to-refresh fetches from `GET /designs?userId=`

---

## 3B Definition of Done

- [ ] Text can be added to the garment and dragged to reposition
- [ ] Font, size, and colour updates reflect live on the mannequin
- [ ] Multiple text layers can be added and individually selected
- [ ] Image can be uploaded, placed on garment, and sized
- [ ] Save flow prompts for name, saves to backend, shows confirmation
- [ ] Saved designs appear in `MyDesignsScreen`
- [ ] 360° preview rotates the mannequin smoothly
- [ ] "Order this design" CTA from preview navigates to order flow

---

# PHASE 3C — AI Design Assistant & Sizing System
### Days 17–20

## Goal
Integrate the OpenAI API for AI-generated design suggestions and build all three paths of the sizing system.

---

## 3C.1 — AI Design Assistant

**File:** `editor/widgets/ai_prompt_bar.dart`

Appears as `EditorBottomPanel` content when AI tab is active.

**UI:**
- Eyebrow label: "AI · ذكاء اصطناعي" in gold
- Multi-line `LolipantsTextField` (max 3 lines), hint from `AppStrings.aiPromptHintAr` / `AppStrings.aiPromptHint`
- Send button (gold 20px circle with arrow icon)
- Below: horizontal scroll of suggestion chips for quick prompts:
  - "Traditional Qatari Thobe with gold trim"
  - "Modern black Abaya with silver embroidery"
  - "Minimalist white Kandura"
  - "Colourful children's Jalabiya"
- AI response area: shows loading shimmer while awaiting response, then renders result

**AI integration — OpenAI API:**

```dart
// editor/data/ai_design_service.dart
class AiDesignService {
  final Dio _dio;

  // Call your Cloudflare Worker which proxies to OpenAI
  // The worker handles the API key — never put the OpenAI key in the Flutter app
  Future<Either<AppException, GarmentDesignSuggestion>> generateDesign({
    required String prompt,
    required String garmentType,
    required String currentStyle,
  });
}
```

**Cloudflare Worker endpoint (proxy):**
```
POST /ai/design
Body: { prompt, garmentType, currentStyle }
Returns: { primaryColour, accentColour, fabricId, patternId, embroideryId, description, descriptionAr }
```

The Worker calls OpenAI with a system prompt that constrains responses to valid `GarmentDesign` fields and returns structured JSON. The Flutter app never holds the OpenAI API key.

**On AI response received:**
1. Parse `GarmentDesignSuggestion` from response
2. Show preview card: description text + colour swatches + fabric name
3. "Apply to design" CTA → updates `editorProvider` with all suggested values, mannequin re-renders
4. "Try again" link → clears and allows new prompt

**Loading state:** 3-dot pulsing animation (`flutter_animate`) while awaiting response

**Error state:** `ErrorBanner` — "Couldn't generate design. Try again. / تعذّر إنشاء التصميم. حاول مرة أخرى."

---

## 3C.2 — Sizing Method Screen

**File:** `sizing/screens/sizing_method_screen.dart`

Entry point for all sizing. Accessible from:
- Editor `ToolRail` ruler icon
- Order flow (before placing an order)

**UI:**
- Header: "How would you like to be measured? / كيف تريد أخذ مقاساتك؟"
- 3 option cards (full-width, `AppColors.stone`, `borderDefault`, `AppRadius.lg`, 16px padding):

| Option | Icon | EN Title | AR Title | EN Subtitle |
|---|---|---|---|---|
| AI | Camera SVG | AI measurement | قياس ذكي | Use your camera for instant sizing |
| Manual | Ruler SVG | Enter manually | إدخال يدوي | Type in your measurements |
| Workshop | Location SVG | Visit workshop | زيارة الورشة | We come to you or you visit us |

- Each card is tappable → navigates to respective sizing screen
- "Use saved measurements" link at bottom (gold, bodyMedium) if user has saved measurements → skips to size confirmation

---

## 3C.3 — AI Measurement Screen

**File:** `sizing/screens/ai_measurement_screen.dart`

**Step 1 — Instructions:**
- Title: "AI measurement / قياس ذكي"
- Numbered instructions list:
  1. Stand 2 metres from the camera in a well-lit room
  2. Wear fitted clothing
  3. Stand straight with arms slightly out
  4. We'll calculate your measurements automatically
- "Start scan / بدء المسح" → `LolipantsButton(primary)` → Step 2

**Step 2 — Camera scan (Phase 3 implementation):**
- For Phase 3: use `camera` package to show live camera feed
- Overlay: silhouette guide (human outline in `AppColors.borderDefault`)
- "Analysing…" label + animated pulsing ring while processing
- Call `POST /ai/measure` Cloudflare Worker endpoint with base64 image
- The Worker calls OpenAI Vision API to estimate measurements and returns structured JSON

**Step 3 — Results:**
- Show estimated `BodyMeasurements` in a clean table:
  - Chest · Waist · Hips · Shoulder width · Height · Arm length (all in cm)
  - Each row: label (dust) + value (sand, titleSmall)
- "These are estimates — please verify before ordering" note in `fog`
- "Save measurements / حفظ المقاسات" CTA → saves to `sizingProvider` + backend
- "Enter manually instead" link → `/sizing/manual`

---

## 3C.4 — Manual Size Entry Screen

**File:** `sizing/screens/manual_size_screen.dart`

**Body Measurements Model:**
```dart
// sizing/models/body_measurements.dart
class BodyMeasurements {
  final double? chest;          // cm
  final double? waist;          // cm
  final double? hips;           // cm
  final double? shoulderWidth;  // cm
  final double? height;         // cm
  final double? armLength;      // cm
  final String? preferredSize;  // 'XS' | 'S' | 'M' | 'L' | 'XL' | 'XXL'
  final DateTime savedAt;
}
```

**UI:**
- Title: "Enter your measurements / أدخل مقاساتك"
- Subtitle: "All measurements in centimetres / جميع المقاسات بالسنتيمتر"
- `LolipantsTextField` for each measurement (numeric keyboard, decimal allowed):
  - Height · Chest · Waist · Hips · Shoulder width · Arm length
- Standard size selector (optional): row of size pills XS · S · M · L · XL · XXL
- "Save / حفظ" → `LolipantsButton(primary)` → saves to `sizingProvider` + `POST /measurements`
- Validation: at least one field must be filled; numeric values only; max 300cm

---

## 3C.5 — Workshop Booking Screen

**File:** `sizing/screens/workshop_booking_screen.dart`

**UI:**
- Title: "Book a sizing visit / احجز موعد قياس"
- Two option cards:
  - "Visit the workshop" — address shown, map thumbnail (static image placeholder)
  - "We come to you" — enter your address, pick a time

**Book visit form (Visit workshop option):**
- Date picker (`showDatePicker`, only future dates, within next 14 days)
- Time slot selector: horizontal chips — Morning 9–12 · Afternoon 12–17 · Evening 17–20
- "Confirm booking / تأكيد الحجز" → `POST /bookings` → show confirmation with booking reference

**Book home visit form (We come to you option):**
- `LolipantsTextField` for address
- `LolipantsTextField` for additional directions
- Date + time slot pickers (same as above)
- "Confirm booking" → same flow

---

## 3C.6 — My Measurements Screen

**File:** `profile/screens/my_measurements_screen.dart`

- Header: "My measurements / مقاساتي"
- If measurements saved: clean table of all saved values + "Last updated" date
- Edit button top-right → `/sizing/manual` with pre-filled values
- "Re-scan with AI" button (secondary) → `/sizing/ai`
- If no measurements: empty state → "Take measurements" CTA → `/sizing`

---

## 3C Definition of Done

- [ ] AI prompt bar accepts input and calls Cloudflare Worker proxy
- [ ] AI response parses and updates mannequin design correctly
- [ ] Quick-prompt chips work as shortcut inputs
- [ ] Error state shows correctly on AI failure
- [ ] Sizing method screen shows 3 options and navigates correctly
- [ ] AI measurement screen shows camera feed and calls measurement endpoint
- [ ] Measurement results display and save to `sizingProvider` + backend
- [ ] Manual size entry validates and saves all fields
- [ ] Workshop booking submits form and shows confirmation with reference
- [ ] `MyMeasurementsScreen` shows saved values and edit shortcut
- [ ] Saved measurements pre-fill the manual entry form

---

---

# PHASE 4 — Community & Marketplace
### Days 21–28 · Complete all of Phase 3 before starting

---

## Phase 4 goal
Build the full social and community layer: fashion news feed, designer showcase marketplace, professional designers listing, design consultation, and the music mini-player.

---

# PHASE 4A — News Feed
### Days 21–23

## Models

```dart
// community/models/post.dart
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool isVerifiedDesigner;
  final String body;
  final List<String> imageUrls;   // R2 URLs
  final List<String> tags;        // e.g. ['abaya', 'gulf', 'wedding']
  final int reactionCount;
  final int commentCount;
  final bool currentUserReacted;
  final DateTime postedAt;
}

enum ReactionType { love, fire, clap, wow }
```

## News Feed Screen

**File:** `community/screens/news_feed_screen.dart`

**UI:**
- `CustomScrollView` with `SliverAppBar` (title "Fashion news / أخبار الموضة", pinned)
- Filter chips below header: All · Abaya · Thobe · Wedding · Modern · Traditional
- `SliverList` of `PostCard` widgets
- Pull-to-refresh → `GET /posts?tag=&page=`
- Infinite scroll: load more on scroll to bottom

**PostCard** (`community/widgets/post_card.dart`)
- `AppColors.stone`, `AppRadius.lg`, `borderSubtle` border
- Top row: author avatar (32px) + name + `isVerifiedDesigner` gold tick icon + time ago
- Body text: `bodyLarge`, max 3 lines with "Read more" expand
- Images: if 1 image → full-width `Image.network` (aspect 4:3); if 2+ → horizontal scroll
- Reactions row:
  - 4 reaction buttons (love ♥ · fire 🔥 · clap 👏 · wow ✨) using custom SVG icons
  - Tapped reaction: gold fill, count increments immediately (optimistic update)
  - Reaction counts displayed next to each icon
- Comment count: tappable → `PostDetailScreen`
- Share icon (top right) — Phase 6

## Post Detail Screen

**File:** `community/screens/post_detail_screen.dart`

- Full post content (no line limit)
- Full image viewer (tap to expand full screen)
- Comment list: `ListView` of comment items (avatar + name + body + time)
- Comment input at bottom (sticky): `LolipantsTextField` + send icon

## Create Post Screen

**File:** `community/screens/create_post_screen.dart`

- Header: "New post / منشور جديد"
- `LolipantsTextField` (multi-line, max 500 chars) with char counter
- Image attachment row: tap to add up to 4 images via `image_picker`
- Tag selector: multi-select chips (Abaya · Thobe · Wedding · Modern · Traditional · Custom)
- Post CTA: `LolipantsButton(primary)` "Post / نشر" → `POST /posts`
- "Cancel" top-left → confirmation dialog if content exists

## 4A Definition of Done

- [ ] News feed loads posts from API with pagination
- [ ] Pull-to-refresh works
- [ ] Filter chips filter by tag
- [ ] Post cards show author, body, images, reaction counts
- [ ] Reaction tap works with optimistic UI update
- [ ] `PostDetailScreen` shows full post and comments
- [ ] Comment input submits and appears in list
- [ ] `CreatePostScreen` submits with images and tags

---

# PHASE 4B — Designer Showcase & Consultations
### Days 24–26

## Designer Showcase Screen

**File:** `community/screens/showcase_screen.dart`

The marketplace where community members share their saved designs and earn commission when another user orders from them.

**UI:**
- `CustomScrollView` with pinned header "Designer showcase / معرض المصممين"
- Sort chips: Trending · Newest · Most ordered
- `SliverGrid(crossAxisCount: 2)` of `ShowcaseCard` widgets
- Each `ShowcaseCard`:
  - Mannequin thumbnail (miniature `CustomPainter`, 160px tall)
  - Designer name + gold verified tick if pro
  - Design name + garment type tag
  - "Order this / اطلب هذا" pill button → navigates to `/order/summary` with design as extra
  - Commission label: "Designer earns X%" in gold (small, bottom)

**Designer commission model:**
- When a user orders a design from the showcase, the original designer earns 10% of the order value
- This is tracked server-side via `designerId` on the order — no client-side logic needed beyond passing `designerId`

## Individual Designer Profile

**File:** `community/screens/designer_profile_screen.dart`

- Header: large avatar, name, bio, follower count
- Gold "Pro Designer" badge if applicable
- `GridView` of their showcase designs (same `ShowcaseCard`)
- "Follow" toggle button (secondary outline → filled on follow)
- Stats row: Designs · Orders earned · Rating

## Professional Designers Screen

**File:** `community/screens/pro_designers_screen.dart`

- Header: "Pro designers / مصممون محترفون"
- `ListView` of `ProDesignerCard` widgets
- `ProDesignerCard`:
  - Horizontal card: avatar (48px) + name + speciality (e.g. "Traditional Gulf · Wedding") + rating
  - "View portfolio / عرض الأعمال" → `DesignerProfileScreen`

## Consultation Screen

**File:** `community/screens/consultation_screen.dart`

For beginner users to request design advice.

**UI:**
- Header: "Design consultations / استشارات التصميم"
- Brief explainer: "Not sure where to start? Our expert designers will help you. / غير متأكد من أين تبدأ؟ مصممونا المحترفون سيساعدونك."
- Active consultation card (if one exists): shows status + assigned designer + last message
- "Request a consultation / طلب استشارة" → `LolipantsButton(primary)` → `ConsultationRequestForm`

**Consultation request form (inline, shown below button):**
- Garment type selector (dropdown: Abaya · Thobe · Wedding dress · Suit · Other)
- `LolipantsTextField` multi-line: "Describe what you're looking for / صف ما تبحث عنه"
- Budget range slider (optional): 100–5000 QAR
- "Submit request / إرسال الطلب" → `POST /consultations`
- On success: show "A designer will be in touch within 24 hours / سيتواصل معك مصمم خلال 24 ساعة"

## 4B Definition of Done

- [ ] Showcase grid loads designs from API
- [ ] "Order this" from showcase passes `designerId` through to order flow
- [ ] Designer profile shows their designs and stats
- [ ] Follow/unfollow toggles and updates count
- [ ] Pro designers list loads from API
- [ ] Consultation request form submits and shows confirmation

---

# PHASE 4C — Music Player
### Days 27–28

## Goal
Replace the `_MusicPlayerSlot` placeholder in `MainShell` with a working mini-player that plays background music while the user designs.

## Music Provider

```dart
// music/providers/music_provider.dart
class MusicState {
  final bool isPlaying;
  final String? currentTrackTitle;
  final String? currentTrackArtist;
  final double progress;        // 0.0–1.0
  final double duration;        // seconds
  final List<Track> queue;
  final int currentIndex;
}

class Track {
  final String id;
  final String title;
  final String artist;
  final String streamUrl;       // R2 URL or external stream
  final String? coverArtUrl;
}
```

Use `just_audio` package for playback. The music player must **not** pause when the screen changes tabs.

## Music Mini Player Widget

**File:** `music/widgets/music_mini_player.dart`

Replaces `_MusicPlayerSlot` in `MainShell`. Only visible when `musicProvider.isPlaying == true` or a track is loaded.

**UI (56px height):**
- `AppColors.stone` background, `borderStrong` top border
- Left: cover art thumbnail (36×36px, `AppRadius.sm`) — placeholder music note icon if null
- Centre: track title (`titleSmall`, 1 line, overflow ellipsis) + artist (`bodySmall`, dust)
- Right: previous icon · play/pause icon (gold, 28px) · next icon
- Background progress bar: thin 2px line at very bottom, gold fill proportional to `progress`
- Tap anywhere on mini player (not on controls) → expand to full player

## Music Expanded Player

**File:** `music/widgets/music_expanded_player.dart`

Shown via `showModalBottomSheet(isScrollControlled: true)`.

- Large cover art (240×240px, `AppRadius.lg`)
- Track title (`displayMedium`) + artist (`bodyLarge`, dust)
- Progress slider: `Slider` with `AppColors.gold` active track
- Time elapsed / total time labels
- Controls row: shuffle · previous · play/pause (large, 56px gold circle) · next · repeat
- Queue list below: `ListView` of queue tracks, current highlighted with gold left border
- Dismiss handle at top

## Default tracks (hardcode for Phase 4):
```dart
const defaultTracks = [
  Track(id: '1', title: 'Oud Sunrise',    artist: 'Gulf Instrumentals', streamUrl: '...'),
  Track(id: '2', title: 'Desert Wind',    artist: 'Arabic Ambient',     streamUrl: '...'),
  Track(id: '3', title: 'Pearls of Doha', artist: 'Khaleeji Jazz',      streamUrl: '...'),
];
```

Use royalty-free instrumentals. Store on Cloudflare R2.

## 4C Definition of Done

- [ ] Mini player appears when a track is loaded
- [ ] Play/pause, previous, next controls work
- [ ] Progress bar updates during playback
- [ ] Music continues playing when tabs are switched
- [ ] Expanded player opens from mini player tap
- [ ] Progress slider seek works
- [ ] Queue is visible and tapping a track plays it
- [ ] Mini player hides when no track is loaded

---

---

# PHASE 5 — Orders, Payments & Delivery
### Days 29–35 · Complete all of Phase 4 before starting

---

## Phase 5 goal
Complete the full order placement flow with Tap Payments, wire real order data to the Orders screen, and build the tailor-facing dashboard.

---

# PHASE 5A — Order Placement Flow
### Days 29–31

## Orders Repository

```dart
// orders/data/orders_repository.dart
abstract class OrdersRepository {
  Future<Either<AppException, List<Order>>> getMyOrders();
  Future<Either<AppException, Order>>       getOrderById(String id);
  Future<Either<AppException, Order>>       placeOrder(PlaceOrderRequest request);
  Future<Either<AppException, void>>        cancelOrder(String id);
}

class PlaceOrderRequest {
  final String designId;
  final String? designerId;       // if ordering from showcase
  final BodyMeasurements measurements;
  final String deliveryAddress;
  final String deliveryPhone;
  final String? deliveryNotes;
  final String paymentToken;      // from Tap Payments SDK
}
```

## Order Summary Screen

**File:** `orders/screens/order_summary_screen.dart`

Entry point of the order flow. Receives a `GarmentDesign` as route extra.

**UI (scrollable):**
- Header: "Order summary / ملخص الطلب"
- Design preview card:
  - Miniature mannequin `CustomPainter` (120px tall)
  - Design name + garment type + fabric + quality
  - Gold edit link → returns to editor
- Sizing section:
  - If measurements saved: show summary table with "Edit" link
  - If no measurements: gold callout "Please add your measurements before ordering" + "Add measurements / إضافة المقاسات" → `/sizing`
- Estimated delivery: `bodyMedium` — "Estimated delivery: 7–14 days / التسليم المتوقع: 7–14 يوماً"
- Price breakdown:
  - Garment base price (from API based on type + quality)
  - Fabric upgrade fee (if premium/suit-grade)
  - Delivery fee
  - Subtotal
  - All in QAR
- "Continue to delivery / متابعة للتوصيل" → `LolipantsButton(primary)` → `/order/delivery`

## Size Confirmation Screen

**File:** `orders/screens/size_confirmation_screen.dart`

- Shown automatically if user has saved measurements
- Displays measurements in table
- "Confirm these measurements / تأكيد هذه المقاسات" → `/order/delivery`
- "Change measurements / تغيير المقاسات" → `/sizing`

## Delivery Details Screen

**File:** `orders/screens/delivery_details_screen.dart`

**Fields:**
- Full delivery address (`LolipantsTextField`, multi-line)
- Apartment / building / floor (optional)
- City (dropdown: Doha · Al Wakrah · Al Khor · Al Rayyan · Lusail · Other)
- Phone number
- Delivery notes (optional)

**Behaviour:**
- Save to `ordersProvider` state
- "Continue to payment / متابعة للدفع" → `/order/payment`

## Payment Screen

**File:** `orders/screens/payment_screen.dart`

**Tap Payments integration:**
- Add `tap_payments_flutter` (or use `tap_card_sdk`) to `pubspec.yaml`
- Show Tap's hosted card entry UI inside the screen
- Tap SDK handles: card number · expiry · CVV · 3D Secure redirect
- On payment success: Tap returns a `token` → call `ordersRepository.placeOrder()` with token
- On payment failure: show `ErrorBanner` with Tap's error message

**Price summary (compact, shown above Tap card form):**
- Total in QAR, large gold `displayMedium`
- Line items collapsed (tappable to expand)

**Notes:**
- Never log or store raw card numbers in the app
- All Tap communication goes through the Tap SDK — do not call Tap API directly from Flutter
- Tap API secret key lives in the Cloudflare Worker only

## Order Confirmation Screen

**File:** `orders/screens/order_confirmation_screen.dart`

Shown on successful `placeOrder()`.

**UI:**
- Full screen, `AppColors.ink`
- Animated gold 8-pointed star icon (`flutter_animate` scale + fade in)
- "Order placed! / تم تقديم الطلب!" in `displayLarge`, gold
- Order reference number: "#XXXX" in `titleMedium`
- "Your tailor will confirm within 2 hours / سيقوم خياطك بالتأكيد خلال ساعتين"
- Status tracker preview: first 3 status steps with `placed` active
- Two buttons:
  - "Track order / تتبع الطلب" (primary) → `/orders/:id`
  - "Continue designing / متابعة التصميم" (secondary) → `/home`

---

## 5A Definition of Done

- [ ] Order summary calculates and displays correct pricing
- [ ] Measurements section shows saved data or prompts to add
- [ ] Delivery details form validates and saves
- [ ] Tap Payments card form loads inside the screen
- [ ] Successful payment calls `placeOrder()` and navigates to confirmation
- [ ] Confirmation screen animates and shows order reference
- [ ] Order appears in `OrdersScreen` with `placed` status

---

# PHASE 5B — Orders Screen & Tailor Dashboard
### Days 32–35

## 5B.1 — Wire Orders Screen to Real Data

Replace mock orders in `OrdersScreen` with real data from `ordersRepository.getMyOrders()`.

- On mount: call `ordersProvider.loadMyOrders()`
- Show `LoadingOverlay` while loading
- `ErrorBanner` on failure with retry button
- Pull-to-refresh calls `loadMyOrders()` again
- `OrderDetailScreen` loads single order via `ordersProvider.getOrderById(id)`
- Status updates poll every 60 seconds via a `Timer.periodic` in `ordersProvider` while screen is active
  - Use `GET /orders/:id` → compare status with cached → update if changed → push notification (Phase 6)

---

## 5B.2 — Tailor Dashboard

The tailor dashboard is a **separate role-based view** within the same app. When a user with `role == 'tailor'` logs in, the main shell is replaced by the tailor shell.

**Tailor route guard:**
```dart
// In app_router.dart redirect:
// If authenticated AND user.role == 'tailor' AND path starts with /home → redirect to /tailor
// If authenticated AND user.role != 'tailor' AND path starts with /tailor → redirect to /home
```

**Tailor Shell** (`features/tailor/shell/tailor_shell.dart`)
- 3-tab bottom nav: Incoming · Active · Completed
- Same `LolipantsBottomNavBar` style but with tailor-specific labels

**Incoming Orders Screen** (`features/tailor/screens/incoming_orders_screen.dart`)
- List of orders with status `placed` or `confirmed` assigned to this tailor
- Each row: order ID · design name · customer name · time placed
- Tap → `TailorOrderDetailScreen`

**TailorOrderDetailScreen** (`features/tailor/screens/tailor_order_detail_screen.dart`)
- Full design viewer: `CustomPainter` mannequin at full size with all design layers rendered
- Customer measurements table
- Action buttons:
  - "Accept order / قبول الطلب" (primary) → updates status to `confirmed`
  - "Decline / رفض" (destructive) → shows reason input dialog → updates status to `cancelled`
- Once accepted: status update row showing current step with CTA to advance:
  - "Mark as cutting / تحديد: قص القماش" → updates to `cutting`
  - "Mark as stitching / تحديد: خياطة" → updates to `stitching`
  - ... and so on through each `OrderStatus`
  - Each status update: `PATCH /orders/:id/status` with `{ status, note }`
- All status updates reflect in real time in the customer's `OrderDetailScreen`

**Active Orders Screen:** same as incoming but filtered to `cutting` through `readyToShip`

**Completed Orders Screen:** filtered to `delivered` or `cancelled`

---

## 5B Definition of Done

- [ ] Orders screen loads real orders from API
- [ ] Pull-to-refresh and 60-second polling work
- [ ] Order detail shows full real timeline
- [ ] Tailor role is detected and tailor shell loads on login
- [ ] Tailor can view full design with all layers rendered
- [ ] Tailor can accept, decline, and advance order through all status steps
- [ ] Status updates appear on customer's order screen within one poll cycle

---

---

# PHASE 6 — Polish, QA & Launch
### Days 36–40 · Complete all of Phase 5 before starting

---

## Phase 6 goal
Final polish, RTL support, full QA, push notifications, performance optimisation, landing page, and app store submission.

---

# PHASE 6A — RTL, Localisation & Profile Completion
### Day 36

## Full RTL Support

Enable proper RTL layout for Arabic:

```dart
// app.dart
MaterialApp.router(
  ...
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('ar'),
  ],
  // Detect device locale or user preference from settingsProvider
  locale: settingsProvider.locale,
)
```

- All `Row` widgets must use `MainAxisAlignment.start` (auto-mirrors in RTL)
- Replace all manual `Directionality` wrappers with proper locale-driven direction
- Test every screen in both LTR and RTL — look for:
  - Icons that should not flip (logos, brand marks) — wrap in `Directionality(ltr)`
  - Icons that should flip (arrows, chevrons) — leave to auto-mirror
  - Text alignment: use `textAlign: TextAlign.start` not `.left`
  - `EdgeInsets`: replace `.only(left: x)` with `.only(start: x)` (use `EdgeInsetsDirectional`)

## Settings Screen

**File:** `profile/screens/settings_screen.dart`

- Language toggle: English ↔ العربية — updates `settingsProvider.locale`, persists in `SharedPreferences`
- Notification preferences (Phase 6B)
- App version label
- Privacy policy link (opens in-app `WebView`)
- Terms of service link
- Delete account (destructive, confirmation dialog, calls `DELETE /auth/account`)

## Edit Profile Screen

**File:** `profile/screens/edit_profile_screen.dart`

- Avatar upload: tap avatar → `image_picker` → upload to R2 → update `PATCH /auth/user`
- `LolipantsTextField` for name
- `LolipantsTextField` for email (readonly if Better Auth does not allow change — show note)
- Save → `PATCH /auth/user`

---

# PHASE 6B — Push Notifications
### Day 37

Use **OneSignal** for push notifications (not Firebase FCM). OneSignal provides its own SDK and does not require Firebase.

```yaml
# pubspec.yaml
onesignal_flutter: ^5.2.6
```

**Setup:**
1. Initialise in `main.dart`: `OneSignal.initialize("YOUR_ONESIGNAL_APP_ID")`
2. Request permission on first order placement (not on app open)
3. Store OneSignal player ID server-side by calling `POST /users/push-token` after init

**Notification triggers (all sent from Cloudflare Worker, not from Flutter):**

| Trigger | Title EN | Title AR |
|---|---|---|
| Order status changes | "Order update" | "تحديث الطلب" |
| Tailor confirms order | "Your order is confirmed!" | "تم تأكيد طلبك!" |
| Order out for delivery | "On its way!" | "في الطريق إليك!" |
| Order delivered | "Delivered!" | "تم التسليم!" |
| New post from followed designer | "New design drop" | "تصميم جديد" |
| Consultation reply | "Designer replied" | "رد المصمم" |

**In-app:** tap on notification → navigate to relevant screen via `OneSignal.Notifications.addClickListener`

---

# PHASE 6C — Performance, QA & Polish
### Days 38–39

## Performance Checklist

- [ ] **Mannequin rendering:** profile `CustomPainter` — `shouldRepaint` must return `false` when only unrelated state changes. Cache `Paint` objects as class-level fields, not inside `paint()`.
- [ ] **Image loading:** wrap all `Image.network` with `CachedNetworkImage` (`cached_network_image` package). Set `memCacheWidth` and `memCacheHeight` to display size.
- [ ] **List performance:** all `ListView` and `GridView` must use builder constructors. No `ListView(children: [])` with more than 10 items.
- [ ] **Riverpod:** audit all `ref.watch` calls — ensure providers are not rebuilt unnecessarily. Use `select` where only part of state is needed.
- [ ] **Editor screen:** wrap `MannequinViewer` in `RepaintBoundary` to isolate its repaint from the rest of the screen.
- [ ] **Startup time:** `main.dart` must do nothing except load `.env` and call `runApp`. Defer all provider initialisation to first frame.

## QA Test Checklist

**Auth:**
- [ ] Sign up with valid data succeeds
- [ ] Sign up with duplicate email shows correct error
- [ ] Login with wrong password shows correct error
- [ ] Session persists across app kill + reopen
- [ ] Logout clears all stored data

**Editor:**
- [ ] Each garment type renders correct mannequin shape
- [ ] Colour changes apply live
- [ ] Text layer adds, moves, and removes correctly
- [ ] Image upload attaches to garment
- [ ] AI prompt returns result and applies to mannequin
- [ ] Save flow stores design to backend
- [ ] 360° preview rotates correctly

**Sizing:**
- [ ] All 3 sizing paths complete without error
- [ ] Saved measurements pre-fill manual form
- [ ] Workshop booking submits and shows reference

**Orders:**
- [ ] Full order flow completes: design → size → delivery → payment → confirmation
- [ ] Tap payment sandbox processes correctly
- [ ] Order appears in orders list with correct status
- [ ] Status updates appear within one poll cycle
- [ ] Tailor can advance status through all steps

**Community:**
- [ ] Feed loads and paginates
- [ ] Reactions update optimistically
- [ ] Post creation with images submits
- [ ] Showcase loads and "Order this" works
- [ ] Consultation request submits

**General:**
- [ ] App runs without error on Android API 24, 30, 34
- [ ] App runs without error on iOS 14, 16, 17
- [ ] All screens usable in RTL (Arabic locale)
- [ ] All screens usable in LTR (English locale)
- [ ] No hard-coded colours, strings, or sizes anywhere
- [ ] No `print()` statements in release build

## Mascot Animation — Rive Integration

Replace the static panda placeholder on the splash screen with the real Rive animation file once it is provided.

```dart
// features/splash/widgets/mascot_animation.dart
RiveAnimation.asset(
  'assets/animations/panda_mascot.riv',
  animations: const ['intro'],   // plays: background → panda reveal → panda wink
  fit: BoxFit.contain,
)
```

For the persistent in-app mascot (bouncing around screen):
```dart
// shared/widgets/mascot_overlay.dart
// OverlayEntry added to Navigator overlay on app init
// Rive animation: 'idle' state — panda moves slowly around screen
// On order confirmed: trigger 'celebrate' state (panda jumps + winks)
// On error: trigger 'sad' state
// Draggable — user can reposition by dragging
// Small (60px) so it doesn't obscure content
```

---

# PHASE 6D — Landing Page & App Store Submission
### Day 40

## Landing Page

Build a single-page marketing website deployed to Cloudflare Pages.

**File:** `landing/index.html` (separate from Flutter project)

**Sections:**
1. Hero — app name "Lolipants" · tagline "Design your fashion. Wear your heritage." · app store badges (placeholder)
2. Features — 3 feature cards: Design · Heritage · Tailored
3. How it works — 4-step timeline: Design → Size → Order → Wear
4. Screenshots — phone mockup gallery (use Flutter screenshots)
5. Download CTA — App Store + Play Store buttons
6. Footer — contact, privacy policy, terms

**Style:** matches the app — dark `#0A0806` background, gold `#C9A84C` accent, Poppins font, arabesque pattern at low opacity.

## Play Store Submission

1. Build release APK: `flutter build appbundle --release`
2. Sign with keystore (generate if not exists, store securely — not in repo)
3. Guide client to create Google Play Console account and pay $25
4. Upload AAB, fill store listing, screenshots, privacy policy URL
5. Submit for review

## App Store Submission

1. Build for iOS: `flutter build ipa --release`
2. Configure in `Xcode`: bundle ID `com.lolipants`, version `1.0.0`, build `1`
3. Guide client to create Apple Developer account and pay $99
4. Upload via Xcode Organiser or `xcrun altool`
5. Fill App Store Connect listing
6. Submit for review

---

## Final Definition of Done — Phase 6

- [ ] App fully localised in English and Arabic with correct RTL layout
- [ ] Language toggle in settings persists and switches layout
- [ ] Push notifications work for all 6 trigger types
- [ ] All QA checklist items above are ticked
- [ ] Mannequin `CustomPainter` profiled and confirmed <16ms per frame
- [ ] All `Image.network` replaced with `CachedNetworkImage`
- [ ] All lists use builder constructors
- [ ] Rive mascot animation plays on splash screen
- [ ] Mascot overlay bounces in-app and reacts to events
- [ ] Landing page deployed on Cloudflare Pages
- [ ] Android AAB built, signed, and submitted to Play Store
- [ ] iOS IPA built, signed, and submitted to App Store
- [ ] All source code, assets, credentials, and deployment keys handed over to client

---

## Final New Dependencies (add to `pubspec.yaml`)

```yaml
# Editor & media
flutter_colorpicker: ^1.1.0
image_picker: ^1.1.2
cached_network_image: ^3.3.1

# 3D / animation
rive: ^0.13.2          # already added in Phase 1

# Camera (AI measurement)
camera: ^0.10.6

# Audio
just_audio: ^0.9.40
audio_session: ^0.1.21

# Push notifications (no Firebase)
onesignal_flutter: ^5.2.6

# Payments
# Follow Tap Payments Flutter SDK installation guide at
# https://developers.tap.company/docs/flutter-sdk
# Add as a git dependency or local path per their docs
```

---

*End of Phases 3–6 instructions.*
*For questions on Phases 1–2 setup, refer to LOLIPANTS_CURSOR_INSTRUCTIONS.md.*
