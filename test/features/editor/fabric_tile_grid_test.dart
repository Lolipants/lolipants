import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/utils/fabric_texture_overlay.dart';

void main() {
  group('fabricTileGridForDest', () {
    test('evenly divides representative abaya dest rect', () {
      const dest = Rect.fromLTWH(40, 20, 300, 500);
      const fabricAspect = 1.0;

      final grid = fabricTileGridForDest(dest, fabricAspect);

      expect(grid.cols, greaterThanOrEqualTo(2));
      expect(grid.rows, greaterThanOrEqualTo(2));
      expect(grid.cols * grid.tileW, closeTo(dest.width, 0.01));
      expect(grid.rows * grid.tileH, closeTo(dest.height, 0.01));
      expect(grid.tileW, inInclusiveRange(kFabricTileMinLogicalPx, dest.width / 2));
      expect(grid.tileH, greaterThan(0));
    });

    test('clamps tile width for very small dest', () {
      const dest = Rect.fromLTWH(0, 0, 80, 120);
      const fabricAspect = 1.5;

      final grid = fabricTileGridForDest(dest, fabricAspect, targetRepeats: 5);

      expect(grid.cols * grid.tileW, closeTo(dest.width, 0.01));
      expect(grid.rows * grid.tileH, closeTo(dest.height, 0.01));
      expect(grid.tileW, greaterThan(0));
    });

    test('clamps tile width for very large dest', () {
      const dest = Rect.fromLTWH(0, 0, 900, 1400);
      const fabricAspect = 0.75;

      final grid = fabricTileGridForDest(dest, fabricAspect, targetRepeats: 5);

      expect(grid.cols * grid.tileW, closeTo(dest.width, 0.01));
      expect(grid.rows * grid.tileH, closeTo(dest.height, 0.01));
      expect(grid.tileW, lessThanOrEqualTo(kFabricTileMaxLogicalPx + 1));
      expect(grid.tileW, greaterThanOrEqualTo(kFabricTileMinLogicalPx));
    });

    test('returns fallback for empty dest', () {
      final grid = fabricTileGridForDest(Rect.zero, 1);

      expect(grid.cols, 1);
      expect(grid.rows, 1);
      expect(grid.tileW, 40);
      expect(grid.tileH, 40);
    });
  });
}
