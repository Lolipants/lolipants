import 'package:flutter/material.dart';

/// Common garment colour names OpenAI may return instead of hex.
const Map<String, String> kAiNamedColourHex = {
  'white': '#FFFFFF',
  'black': '#000000',
  'ivory': '#FFFFF0',
  'cream': '#FFFDD0',
  'gold': '#C9A84C',
  'silver': '#C0C0C0',
  'navy': '#162F28',
  'plum': '#4A1942',
  'burgundy': '#722F37',
  'emerald': '#162F28',
  'beige': '#E8E4EA',
  'grey': '#808080',
  'gray': '#808080',
};

/// Normalizes AI colour output to `#RRGGBB` (handles hex and colour names).
String normalizeAiColourHex(
  String? raw, {
  String fallback = '#162F28',
}) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return fallback;

  var body = trimmed;
  if (body.startsWith('#')) body = body.substring(1);
  if (RegExp(r'^[0-9A-Fa-f]{3}$').hasMatch(body)) {
    body = body.split('').map((c) => '$c$c').join();
  }
  if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(body)) {
    return '#${body.toUpperCase()}';
  }
  if (RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(body)) {
    return '#${body.substring(2).toUpperCase()}';
  }

  final named = kAiNamedColourHex[trimmed.toLowerCase()];
  if (named != null) return named;

  return fallback;
}

/// Parses AI colour strings into a [Color], never throws.
Color parseAiColour(String? raw, {Color fallback = const Color(0xFF162F28)}) {
  final fb = fallback.toARGB32().toRadixString(16).padLeft(8, '0');
  final fallbackHex = '#${fb.substring(2).toUpperCase()}';
  final hex = normalizeAiColourHex(raw, fallback: fallbackHex);
  final body = hex.replaceAll('#', '');
  final parsed = int.tryParse('FF$body', radix: 16);
  return parsed != null ? Color(parsed) : fallback;
}
