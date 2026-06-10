import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';
import 'package:lolipants/features/wedding/models/wedding_flow_args.dart';
import 'package:lolipants/features/wedding/widgets/wedding_fulfillment_choices.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Standalone Rent / Buy step before the wedding dress catalogue (Browse entry).
class WeddingFulfillmentScreen extends ConsumerWidget {
  const WeddingFulfillmentScreen({super.key});

  static const double _maxButtonWidth = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kFeatureWeddingFlow) {
      return const Scaffold(
        body: Center(child: Text('Wedding flow is not available')),
      );
    }

    final locale = ref.watch(settingsLocaleProvider);
    final isAr = locale.languageCode == 'ar';
    final buttonWidth = MediaQuery.sizeOf(context).width - 48;
    final choiceWidth =
        buttonWidth > _maxButtonWidth ? _maxButtonWidth : buttonWidth;

    void onSelect(WeddingFulfillment fulfillment) {
      context.push(
        '/wedding/dresses',
        extra: WeddingFlowArgs(fulfillment: fulfillment),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromLocale(
            locale,
            AppStrings.editorTabWedding,
            AppStrings.editorTabWeddingAr,
          ),
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizedFromLocale(
                      locale,
                      AppStrings.homeFlowStepWeddingFulfillment,
                      AppStrings.homeFlowStepWeddingFulfillmentAr,
                    ),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  WeddingFulfillmentChoices(
                    choiceWidth: choiceWidth,
                    isAr: isAr,
                    onRent: () => onSelect(WeddingFulfillment.rent),
                    onBuy: () => onSelect(WeddingFulfillment.buy),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
