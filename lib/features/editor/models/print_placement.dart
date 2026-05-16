/// Image print placement presets on the garment hero.
enum PrintPlacement {
  chest,
  back,
  fullFront,
}

/// Parses API / metadata placement strings.
PrintPlacement parsePrintPlacement(String? raw) {
  return switch (raw?.trim().toLowerCase()) {
    'back' => PrintPlacement.back,
    'fullfront' || 'full_front' => PrintPlacement.fullFront,
    _ => PrintPlacement.chest,
  };
}
