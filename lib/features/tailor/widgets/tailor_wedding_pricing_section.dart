import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/tailor/data/tailor_wedding_pricing_repository.dart';
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
              fallback: 'Could not save wedding pricing',
              networkMessage: 'Network issue while saving wedding pricing.',
              authMessage: 'Your session has expired. Please sign in again.',
            ),
          ),
        ),
      ),
      (_) {
        ref.invalidate(tailorWeddingPricingProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wedding pricing saved')),
        );
      },
    );
    if (mounted) setState(() => _saving = false);
  }

  String _labelFor(String category) {
    switch (category) {
      case 'wedding_dress':
        return 'Bridal gown';
      case 'bridesmaid':
        return 'Bridesmaid';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tailorWeddingPricingProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Wedding pricing: $e'),
      data: (catalog) {
        if (_rentControllers.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _bind(catalog));
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Wedding pricing', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Rent per day, sale price, and insurance deposit by category.',
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
                      Text(_labelFor(cat), style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _rentControllers[cat],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Rent / day (QAR)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _saleControllers[cat],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Sale price (QAR)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _depositControllers[cat],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Insurance deposit (QAR)',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            LolipantsButton(
              label: 'Save wedding pricing',
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
