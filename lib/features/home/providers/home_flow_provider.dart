import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/home/models/home_flow_selection.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';

/// In-progress selections on the home design wizard.
final homeFlowSelectionProvider =
    StateNotifierProvider<HomeFlowNotifier, HomeFlowSelection>((ref) {
  return HomeFlowNotifier(ref);
});

class HomeFlowNotifier extends StateNotifier<HomeFlowSelection> {
  HomeFlowNotifier(this._ref) : super(const HomeFlowSelection());

  final Ref _ref;

  /// Restarts the wizard at the gender step.
  void resetToStart() {
    state = const HomeFlowSelection();
  }

  Future<void> setGender(String gender) async {
    await _ref.read(userGenderProvider.notifier).persistGender(gender);
    state = state.copyWith(
      gender: gender,
      clearStyle: true,
      clearServiceType: true,
      clearWeddingFulfillment: true,
    );
  }

  void setStyle(HomeStyleLane style) {
    state = state.copyWith(
      style: style,
      clearServiceType: true,
      clearWeddingFulfillment: true,
    );
  }

  void setServiceType(HomeServiceType serviceType) {
    state = state.copyWith(serviceType: serviceType);
  }

  void setWeddingFulfillment(WeddingFulfillment fulfillment) {
    state = state.copyWith(weddingFulfillment: fulfillment);
  }

  /// Back from style step → gender step.
  void clearFromStyle() {
    state = state.copyWith(
      clearGender: true,
      clearStyle: true,
      clearServiceType: true,
      clearWeddingFulfillment: true,
    );
  }

  /// Back from service or confirm step.
  void clearServiceType() {
    state = state.copyWith(
      clearServiceType: true,
      clearWeddingFulfillment: true,
    );
  }
}
