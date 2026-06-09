import 'dart:ui' show Locale;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/orders_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/location/delivery_location_service.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
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
    final accessoryDraft = ref.read(accessoryCheckoutDraftProvider);
    final weddingDraft = ref.read(weddingCheckoutDraftProvider);
    final draft = ref.read(checkoutDraftProvider);
    final activeAddress =
        accessoryDraft?.address ?? weddingDraft?.address ?? draft?.address ?? '';
    _addressController = TextEditingController(text: activeAddress);
    _cityController =
        TextEditingController(
            text: accessoryDraft?.city ?? weddingDraft?.city ?? draft?.city ?? 'Doha');
    _phoneController = TextEditingController(
        text: accessoryDraft?.phone ?? weddingDraft?.phone ?? draft?.phone ?? '');
    _notesController = TextEditingController(
        text: accessoryDraft?.notes ?? weddingDraft?.notes ?? draft?.notes ?? '');
    _deliveryLat =
        accessoryDraft?.deliveryLat ?? weddingDraft?.deliveryLat ?? draft?.deliveryLat;
    _deliveryLng =
        accessoryDraft?.deliveryLng ?? weddingDraft?.deliveryLng ?? draft?.deliveryLng;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _collectLocation(
        preferCached: _deliveryLat != null && _deliveryLng != null,
      ),
    );
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

  void _saveAndContinue(Locale locale) {
    if (!_formKey.currentState!.validate()) return;
    final accessoryDraft = ref.read(accessoryCheckoutDraftProvider);
    final weddingDraft = ref.read(weddingCheckoutDraftProvider);
    final draft = ref.read(checkoutDraftProvider);
    if (accessoryDraft == null && weddingDraft == null && draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedFromLocale(
              locale,
              OrdersStrings.checkoutExpiredRestart,
              OrdersStrings.checkoutExpiredRestartAr,
            ),
          ),
        ),
      );
      return;
    }
    final lat = _deliveryLat;
    final lng = _deliveryLng;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedFromLocale(
              locale,
              OrdersStrings.detectingLocation,
              OrdersStrings.detectingLocationAr,
            ),
          ),
        ),
      );
      return;
    }
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final phone = _phoneController.text.trim();
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    if (accessoryDraft != null) {
      ref.read(accessoryCheckoutDraftProvider.notifier).state =
          accessoryDraft.copyWith(
        address: address,
        city: city,
        phone: phone,
        notes: notes,
        deliveryLat: lat,
        deliveryLng: lng,
        quote: null,
      );
      context.push('/order/accessory-quote-review');
      return;
    }
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

  Widget _locationStatusCard(Locale locale) {
    final resolved = _resolvedLocation;
    final label = _locating
        ? localizedFromLocale(
            locale,
            OrdersStrings.detectingLocationEllipsis,
            OrdersStrings.detectingLocationEllipsisAr,
          )
        : resolved?.statusLabel ??
            localizedFromLocale(
              locale,
              OrdersStrings.preparingLocation,
              OrdersStrings.preparingLocationAr,
            );
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
              child: Text(
                localizedFromLocale(
                  locale,
                  OrdersStrings.refresh,
                  OrdersStrings.refreshAr,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    final requiredLabel = localizedFromLocale(
      locale,
      OrdersStrings.required,
      OrdersStrings.requiredAr,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromLocale(
            locale,
            OrdersStrings.deliveryDetailsTitle,
            OrdersStrings.deliveryDetailsTitleAr,
          ),
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  localizedFromLocale(
                    locale,
                    OrdersStrings.deliveryPrompt,
                    OrdersStrings.deliveryPromptAr,
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  localizedFromLocale(
                    locale,
                    OrdersStrings.deliveryLocationHint,
                    OrdersStrings.deliveryLocationHintAr,
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.fog,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _locationStatusCard(locale),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: localizedFromLocale(
                      locale,
                      OrdersStrings.streetAddress,
                      OrdersStrings.streetAddressAr,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().length < 5) ? requiredLabel : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: localizedFromLocale(
                      locale,
                      OrdersStrings.city,
                      OrdersStrings.cityAr,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? requiredLabel : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: localizedFromLocale(
                      locale,
                      OrdersStrings.phone,
                      OrdersStrings.phoneAr,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().length < 6)
                      ? localizedFromLocale(
                          locale,
                          OrdersStrings.enterReachablePhone,
                          OrdersStrings.enterReachablePhoneAr,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: localizedFromLocale(
                      locale,
                      OrdersStrings.deliveryNotesOptional,
                      OrdersStrings.deliveryNotesOptionalAr,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                LolipantsButton(
                  label: _locating
                      ? localizedFromLocale(
                          locale,
                          OrdersStrings.detectingLocationEllipsis,
                          OrdersStrings.detectingLocationEllipsisAr,
                        )
                      : localizedFromLocale(
                          locale,
                          OrdersStrings.getPriceAndTailor,
                          OrdersStrings.getPriceAndTailorAr,
                        ),
                  onPressed: _locating ? null : () => _saveAndContinue(locale),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
