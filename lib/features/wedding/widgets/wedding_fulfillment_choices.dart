import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/home/widgets/home_flow_choice_button.dart';

/// Frosted Rent / Buy choices shared by home wizard and browse fulfillment.
class WeddingFulfillmentChoices extends StatelessWidget {
  const WeddingFulfillmentChoices({
    required this.choiceWidth,
    required this.isAr,
    required this.onRent,
    required this.onBuy,
    super.key,
  });

  final double choiceWidth;
  final bool isAr;
  final VoidCallback onRent;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeFlowChoiceButton(
          buttonWidth: choiceWidth,
          isAr: isAr,
          icon: Icons.event_available_outlined,
          label: localizedFromLocale(
            locale,
            AppStrings.weddingRent,
            AppStrings.weddingRentAr,
          ),
          subtitle: localizedFromLocale(
            locale,
            AppStrings.homeFlowWeddingRentBody,
            AppStrings.homeFlowWeddingRentBodyAr,
          ),
          onTap: onRent,
        ),
        const SizedBox(height: AppSpacing.md),
        HomeFlowChoiceButton(
          buttonWidth: choiceWidth,
          isAr: isAr,
          icon: Icons.shopping_bag_outlined,
          label: localizedFromLocale(
            locale,
            AppStrings.weddingBuy,
            AppStrings.weddingBuyAr,
          ),
          subtitle: localizedFromLocale(
            locale,
            AppStrings.homeFlowWeddingBuyBody,
            AppStrings.homeFlowWeddingBuyBodyAr,
          ),
          onTap: onBuy,
        ),
      ],
    );
  }
}
