import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/utils/ai_colour_parse.dart';

void main() {
  test('normalizeAiColourHex maps named colours and hex', () {
    expect(normalizeAiColourHex('white'), '#FFFFFF');
    expect(normalizeAiColourHex('gold'), '#C9A84C');
    expect(normalizeAiColourHex('#FFF'), '#FFFFFF');
    expect(normalizeAiColourHex('162F28'), '#162F28');
  });

  test('parseAiColour never throws on invalid input', () {
    expect(
      parseAiColour('not-a-colour', fallback: Colors.red).toARGB32(),
      Colors.red.toARGB32(),
    );
  });
}
