import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/orders/models/order_estimate.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

/// Debounced garment price estimate for the active editor design.
final editorEstimateProvider =
    AsyncNotifierProvider<EditorEstimateNotifier, OrderEstimate?>(
  EditorEstimateNotifier.new,
);

class EditorEstimateNotifier extends AsyncNotifier<OrderEstimate?> {
  Timer? _debounce;

  @override
  Future<OrderEstimate?> build() async {
    ref.listen<EditorState>(editorProvider, (previous, next) {
      if (previous?.garmentType != next.garmentType ||
          previous?.fabricQuality != next.fabricQuality) {
        _scheduleFetch(next.garmentType, next.fabricQuality);
      }
    });

    final editor = ref.read(editorProvider);
    return _fetch(editor.garmentType, editor.fabricQuality);
  }

  void _scheduleFetch(String garmentType, String fabricQuality) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.invalidateSelf();
    });
  }

  Future<OrderEstimate?> _fetch(String garmentType, String fabricQuality) async {
    if (garmentType.trim().isEmpty) return null;
    final repo = ref.read(ordersRepositoryProvider);
    final result = await repo.getEstimate(
      garmentType: garmentType,
      fabricQuality: fabricQuality,
    );
    return result.fold((_) => null, (est) => est);
  }
}
