import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/location/delivery_location_service.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/features/orders/models/checkout_draft.dart';
import 'package:lolipants/features/orders/models/wedding_checkout_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Collects delivery address and map coordinates for tailor assignment.
class DeliveryDetailsScreen extends ConsumerStatefulWidget {
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

  double? _deliveryLat;
  double? _deliveryLng;
  bool _locating = true;
  ResolvedDeliveryLocation? _resolvedLocation;

  @override
  void initState() {
    super.initState();
    final weddingDraft = ref.read(weddingCheckoutDraftProvider);
    final draft = ref.read(checkoutDraftProvider);
    final activeAddress = weddingDraft?.address ?? draft?.address ?? '';
    _addressController = TextEditingController(text: activeAddress);
    _cityController =
        TextEditingController(text: weddingDraft?.city ?? draft?.city ?? 'Doha');
    _phoneController =
        TextEditingController(text: weddingDraft?.phone ?? draft?.phone ?? '');
    _notesController =
        TextEditingController(text: weddingDraft?.notes ?? draft?.notes ?? '');
    _deliveryLat = weddingDraft?.deliveryLat ?? draft?.deliveryLat;
    _deliveryLng = weddingDraft?.deliveryLng ?? draft?.deliveryLng;
    WidgetsBinding.instance.addPostFrameCallback((_) => _collectLocation());
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _collectLocation({bool preferCached = false}) async {
    if (!mounted) return;
    setState(() => _locating = true);
    if (!preferCached) {
      await DevicePermissionPrompt.ensure(
        context,
        AppDevicePermission.location,
      );
    }
    if (!mounted) return;
    final draft = ref.read(checkoutDraftProvider);
    final resolved = await DeliveryLocationService.resolve(
      cachedLat: draft?.deliveryLat ?? _deliveryLat,
      cachedLng: draft?.deliveryLng ?? _deliveryLng,
      preferCached: preferCached,
    );
    if (!mounted) return;
    setState(() {
      _locating = false;
      _resolvedLocation = resolved;
      _deliveryLat = resolved.lat;
      _deliveryLng = resolved.lng;
    });
  }

  void _saveAndContinue() {
    if (!_formKey.currentState!.validate()) return;
    final weddingDraft = ref.read(weddingCheckoutDraftProvider);
    final draft = ref.read(checkoutDraftProvider);
    if (weddingDraft == null && draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout session expired. Restart.')),
      );
      return;
    }
    final lat = _deliveryLat;
    final lng = _deliveryLng;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still detecting your location. Wait a moment.')),
      );
      return;
    }
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final phone = _phoneController.text.trim();
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    if (weddingDraft != null) {
      ref.read(weddingCheckoutDraftProvider.notifier).state =
          weddingDraft.copyWith(
        address: address,
        city: city,
        phone: phone,
        notes: notes,
        deliveryLat: lat,
        deliveryLng: lng,
        quote: null,
      );
      context.push('/order/wedding-quote-review');
      return;
    }
    ref.read(checkoutDraftProvider.notifier).state = draft!.copyWith(
      address: address,
      city: city,
      phone: phone,
      notes: notes,
      deliveryLat: lat,
      deliveryLng: lng,
      quote: null,
    );
    context.push('/order/quote-review');
  }

  Widget _locationStatusCard() {
    final resolved = _resolvedLocation;
    final label = _locating
        ? 'Detecting your location…'
        : resolved?.statusLabel ?? 'Preparing location…';
    final icon = _locating
        ? null
        : switch (resolved?.source) {
            ResolvedLocationSource.gps => Icons.gps_fixed,
            ResolvedLocationSource.cached => Icons.place_outlined,
            _ => Icons.location_off_outlined,
          };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.smoke,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_locating)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (icon != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: AppSpacing.sm),
              child: Icon(icon, size: 20, color: AppColors.ink),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                if (!_locating && resolved != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${resolved.lat.toStringAsFixed(4)}, '
                    '${resolved.lng.toStringAsFixed(4)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.fog,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!_locating)
            TextButton(
              onPressed: () => _collectLocation(),
              child: const Text('Refresh'),
            ),
        ],
      ),
    );
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We use your location automatically to assign the nearest tailor.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.fog,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _locationStatusCard(),
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
                LolipantsButton(
                  label: _locating ? 'Detecting location…' : 'Get price & tailor',
                  onPressed: _locating ? null : _saveAndContinue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
