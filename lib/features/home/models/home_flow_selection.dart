import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';

/// Style lane in the home design wizard.
enum HomeStyleLane {
  traditional,
  modern,
  wedding,
}

/// How the shopper wants to create their garment.
enum HomeServiceType {
  designYourself,
  finishProduct,
}

/// Active panel in the home design wizard.
enum HomeFlowStep {
  gender,
  style,
  service,
  confirm,
}

/// First incomplete step drives which panel is shown.
HomeFlowStep activeStepFor(HomeFlowSelection selection) {
  if (selection.gender == null) return HomeFlowStep.gender;
  if (selection.style == null) return HomeFlowStep.style;
  if (selection.style == HomeStyleLane.wedding) {
    if (selection.weddingFulfillment == null) return HomeFlowStep.service;
    return HomeFlowStep.confirm;
  }
  if (selection.serviceType == null) return HomeFlowStep.service;
  return HomeFlowStep.confirm;
}

/// In-progress choices on the home design flow.
class HomeFlowSelection {
  const HomeFlowSelection({
    this.gender,
    this.style,
    this.serviceType,
    this.weddingFulfillment,
  });

  final String? gender;
  final HomeStyleLane? style;
  final HomeServiceType? serviceType;
  final WeddingFulfillment? weddingFulfillment;

  bool get isWeddingStyle => style == HomeStyleLane.wedding;

  bool get isComplete {
    if (gender == null || style == null) return false;
    if (isWeddingStyle) return weddingFulfillment != null;
    return serviceType != null;
  }

  HomeFlowSelection copyWith({
    String? gender,
    HomeStyleLane? style,
    HomeServiceType? serviceType,
    WeddingFulfillment? weddingFulfillment,
    bool clearGender = false,
    bool clearStyle = false,
    bool clearServiceType = false,
    bool clearWeddingFulfillment = false,
  }) {
    return HomeFlowSelection(
      gender: clearGender ? null : (gender ?? this.gender),
      style: clearStyle ? null : (style ?? this.style),
      serviceType:
          clearServiceType ? null : (serviceType ?? this.serviceType),
      weddingFulfillment: clearWeddingFulfillment
          ? null
          : (weddingFulfillment ?? this.weddingFulfillment),
    );
  }

  /// Wedding style is only offered for women.
  bool get showWeddingStyle =>
      gender == UserGenderPreference.women;
}

/// Payload for `/mannequin-selector` when opening from home or browse.
class MannequinSelectorArgs {
  const MannequinSelectorArgs({this.preset, this.homeFlow});

  final EditorPresetArgs? preset;
  final HomeFlowSelection? homeFlow;
}
