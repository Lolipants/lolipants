import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/tailor_strings.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/features/tailor/models/tailor_wedding_pricing.dart';
import 'package:lolipants/features/tailor/providers/tailor_wedding_pricing_providers.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Bridal / bridesmaid rent, sale, and deposit overrides.
class TailorWeddingPricingSection extends ConsumerStatefulWidget {
  const TailorWeddingPricingSection({super.key});

  @override
  ConsumerState<TailorWeddingPricingSection> createState() =>
      _TailorWeddingPricingSectionState();
}

class _TailorWeddingPricingSectionState
    extends ConsumerState<TailorWeddingPricingSection> {
  final _rentControllers = <String, TextEditingController>{};
  final _saleControllers = <String, TextEditingController>{};
  final _depositControllers = <String, TextEditingController>{};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _rentControllers.values) {
      c.dispose();
    }
    for (final c in _saleControllers.values) {
      c.dispose();
    }
    for (final c in _depositControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _bind(TailorWeddingPricingCatalog catalog) {
    for (final c in _rentControllers.values) {
      c.dispose();
    }
    for (final c in _saleControllers.values) {
      c.dispose();
    }
    for (final c in _depositControllers.values) {
      c.dispose();
    }
    _rentControllers.clear();
    _saleControllers.clear();
    _depositControllers.clear();

    for (final row in catalog.prices) {
      _rentControllers[row.category] =
          TextEditingController(text: row.rentPricePerDay.toStringAsFixed(0));
      _saleControllers[row.category] =
          TextEditingController(text: row.salePrice.toStringAsFixed(0));
      _depositControllers[row.category] = TextEditingController(
        text: row.insuranceDeposit.toStringAsFixed(0),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final locale = ref.read(settingsLocaleProvider);
    final repo = ref.read(tailorWeddingPricingRepositoryProvider);
    final prices = _rentControllers.keys.map((category) {
      return {
        'category': category,
        'rentPricePerDay': double.tryParse(_rentControllers[category]!.text) ?? 0,
        'salePrice': double.tryParse(_saleControllers[category]!.text) ?? 0,
        'insuranceDeposit':
            double.tryParse(_depositControllers[category]!.text) ?? 0,
      };
    }).toList(growable: false);
    final result = await repo.updatePrices(prices);
    if (!mounted) return;
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mapAppExceptionMessage(
              e,
              fallback: localizedFromLocale(
                locale,
                TailorStrings.couldNotSaveWeddingPricing,
                TailorStrings.couldNotSaveWeddingPricingAr,
              ),
              networkMessage: localizedFromLocale(
                locale,
                TailorStrings.networkIssueSavingWeddingPricing,
                TailorStrings.networkIssueSavingWeddingPricingAr,
              ),
              authMessage: localizedFromLocale(
                locale,
                TailorStrings.sessionExpired,
                TailorStrings.sessionExpiredAr,
              ),
            ),
          ),
        ),
      ),
      (_) {
        ref.invalidate(tailorWeddingPricingProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizedFromLocale(
                locale,
                TailorStrings.weddingPricingSaved,
                TailorStrings.weddingPricingSavedAr,
              ),
            ),
          ),
        );
      },
    );
    if (mounted) setState(() => _saving = false);
  }

  String _labelFor(String category, Locale locale) {
    switch (category) {
      case 'wedding_dress':
        return localizedFromLocale(
          locale,
          TailorStrings.bridalGown,
          TailorStrings.bridalGownAr,
        );
      case 'bridesmaid':
        return localizedFromLocale(
          locale,
          TailorStrings.bridesmaid,
          TailorStrings.bridesmaidAr,
        );
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    final async = ref.watch(tailorWeddingPricingProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(TailorStrings.weddingPricingError(e, locale)),
      data: (catalog) {
        if (_rentControllers.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _bind(catalog));
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizedFromLocale(
                locale,
                TailorStrings.weddingPricing,
                TailorStrings.weddingPricingAr,
              ),
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              localizedFromLocale(
                locale,
                TailorStrings.weddingPricingSubtitle,
                TailorStrings.weddingPricingSubtitleAr,
              ),
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...catalog.prices.map((row) {
              final cat = row.category;
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                color: AppColors.stone,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelFor(cat, locale),
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _rentControllers[cat],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: localizedFromLocale(
                            locale,
                            TailorStrings.rentPerDayQar,
                            TailorStrings.rentPerDayQarAr,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _saleControllers[cat],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: localizedFromLocale(
                            locale,
                            TailorStrings.salePriceQar,
                            TailorStrings.salePriceQarAr,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _depositControllers[cat],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: localizedFromLocale(
                            locale,
                            TailorStrings.insuranceDepositQar,
                            TailorStrings.insuranceDepositQarAr,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            LolipantsButton(
              label: localizedFromLocale(
                locale,
                TailorStrings.saveWeddingPricing,
                TailorStrings.saveWeddingPricingAr,
              ),
              loading: _saving,
              variant: LolipantsButtonVariant.secondary,
              onPressed: _saving ? null : _save,
            ),
          ],
        );
      },
    );
  }
}
