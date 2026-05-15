/// Short chip label + **user direction** for casual basics (same voice as the
/// editor studio traditional quick-prompt chips).
///
/// `kAiLookPromptSuffix` (`ai_look_prompt_suffix.dart`) is sent separately as
/// `aiLookPromptSuffix` and appended on the server; do not repeat it here.
///
/// Shown when the Designs filter is **Casual** or **Modern**, or for casual
/// garment types (`tshirt`, `polo`, `jumpsuit`).
const List<(String chipLabel, String fullPrompt)>
    kCasualGarmentAiPromptPairs = <(String, String)>[
  (
    'White tee',
    'Plain white cotton crew-neck tee, flat-lay catalogue look, soft folds, '
        'clean hem and collar, no graphics',
  ),
  (
    'Grey tee',
    'Heather grey crew-neck tee, relaxed retail styling, even lighting, '
        'no logo',
  ),
  (
    'Black tee',
    'Solid black slim-fit crew-neck tee, matte jersey, minimal shine, crisp '
        'silhouette',
  ),
  (
    'White hoodie',
    'Plain white pullover hoodie, kangaroo pocket and drawstrings, medium '
        'fleece, front view, no branding',
  ),
  (
    'Grey hoodie',
    'Medium heather grey pullover hoodie, relaxed fit, brushed fleece, hood '
        'laid flat',
  ),
  (
    'Black hoodie',
    'Black pullover hoodie, matte fleece, kangaroo pocket visible, understated '
        'streetwear tone',
  ),
  (
    'White long sleeve',
    'Plain white long-sleeve crew-neck, light cotton jersey, sleeves extended '
        'naturally, no print',
  ),
  (
    'Grey long sleeve',
    'Light grey marl long-sleeve crew-neck base layer, fine knit texture, even '
        'lighting',
  ),
  (
    'Black long sleeve',
    'Black long-sleeve crew-neck, soft cotton, slim silhouette, no graphics',
  ),
  (
    'White trousers',
    'Off-white straight-leg chinos, pressed crease, belt loops, plain front, '
        'no pattern',
  ),
  (
    'Grey trousers',
    'Charcoal grey casual trousers or joggers, tapered leg, soft texture, '
        'drawstring or plain waist',
  ),
  (
    'Black trousers',
    'Black slim casual trousers, matte woven fabric, minimal creasing, '
        'plain or five-pocket front',
  ),
];
