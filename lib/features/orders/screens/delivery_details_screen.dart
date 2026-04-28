import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Collects the delivery address for the active checkout draft.
class DeliveryDetailsScreen extends ConsumerStatefulWidget {
  /// Default constructor.
  const DeliveryDetailsScreen({super.key});

  @override
  ConsumerState<DeliveryDetailsScreen> createState() =>
      _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends ConsumerState<DeliveryDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  bool _refetchingQuote = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(checkoutDraftProvider);
    _addressController = TextEditingController(text: draft?.address ?? '');
    _cityController = TextEditingController(text: draft?.city ?? 'Doha');
    _phoneController = TextEditingController(text: draft?.phone ?? '');
    _notesController = TextEditingController(text: draft?.notes ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = ref.read(checkoutDraftProvider);
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout session expired. Restart.')),
      );
      return;
    }
    final city = _cityController.text.trim();
    final needsQuoteRefresh =
        draft.quote == null || draft.quote!.city.toLowerCase() != city.toLowerCase();
    ref.read(checkoutDraftProvider.notifier).state = draft.copyWith(
      address: _addressController.text.trim(),
      city: city,
      phone: _phoneController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (needsQuoteRefresh) {
      setState(() => _refetchingQuote = true);
      final designId = draft.design.designId;
      if (designId != null && designId.isNotEmpty) {
        final repo = ref.read(ordersRepositoryProvider);
        final result = await repo.getQuote(designId: designId, city: city);
        if (!mounted) return;
        result.fold(
          (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  orderErrorMessage(e, fallback: 'Could not refresh price.'),
                ),
              ),
            );
          },
          (quote) {
            final current = ref.read(checkoutDraftProvider);
            if (current != null) {
              ref.read(checkoutDraftProvider.notifier).state =
                  current.copyWith(quote: quote);
            }
          },
        );
      }
      if (!mounted) return;
      setState(() => _refetchingQuote = false);
    }
    if (!mounted) return;
    context.push('/order/payment');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery details')),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Where should we deliver your order?',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Street address',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().length < 5) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().length < 6)
                      ? 'Enter a reachable phone'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Delivery notes (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.smoke,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    'Delivery fee is calculated from the city at the next step.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                LolipantsButton(
                  label: _refetchingQuote
                      ? 'Refreshing price...'
                      : 'Continue to payment',
                  onPressed: _refetchingQuote ? null : _saveAndContinue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
