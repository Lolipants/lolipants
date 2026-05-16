import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/location/delivery_location_service.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/tailor/models/tailor_pricing_catalog.dart';
import 'package:lolipants/features/tailor/providers/tailor_pricing_providers.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Tailor workshop location + garment price matrix + delivery fees.
class TailorPricingScreen extends ConsumerStatefulWidget {
  const TailorPricingScreen({super.key});

  @override
  ConsumerState<TailorPricingScreen> createState() => _TailorPricingScreenState();
}

class _TailorPricingScreenState extends ConsumerState<TailorPricingScreen> {
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Doha');
  final _latController = TextEditingController(text: '25.2854');
  final _lngController = TextEditingController(text: '51.5310');
  double _radiusKm = 50;
  bool _acceptingOrders = false;
  bool _saving = false;
  bool _workshopLocating = false;
  String? _workshopLocationNote;
  bool _workshopGpsFilled = false;

  final Map<String, TextEditingController> _baseControllers = {};
  final Map<String, TextEditingController> _fabricControllers = {};
  final Map<String, TextEditingController> _deliveryControllers = {};

  List<String> _garmentTypes = kTailorGarmentTypes;
  List<String> _fabricQualities = kTailorFabricQualities;

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    for (final c in _baseControllers.values) {
      c.dispose();
    }
    for (final c in _fabricControllers.values) {
      c.dispose();
    }
    for (final c in _deliveryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _cellKey(String garment, String fabric) => '$garment|$fabric';

  void _bindCatalog(TailorPricingCatalog catalog) {
    final profile = catalog.profile;
    _shopNameController.text = profile?.shopName ?? '';
    _addressController.text = profile?.address ?? '';
    _cityController.text = profile?.city ?? 'Doha';
    final hasSavedCoords = profile?.lat != null && profile?.lng != null;
    if (profile?.lat != null) {
      _latController.text = profile!.lat!.toStringAsFixed(5);
    }
    if (profile?.lng != null) {
      _lngController.text = profile!.lng!.toStringAsFixed(5);
    }
    _radiusKm = profile?.serviceRadiusKm ?? 50;
    _acceptingOrders = profile?.isAcceptingOrders ?? false;
    if (!hasSavedCoords && !_workshopGpsFilled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _autoDetectWorkshopLocation();
      });
    }

    if (catalog.garmentTypes.isNotEmpty) {
      _garmentTypes = catalog.garmentTypes;
    }
    if (catalog.fabricQualities.isNotEmpty) {
      _fabricQualities = catalog.fabricQualities;
    }

    for (final c in _baseControllers.values) {
      c.dispose();
    }
    for (final c in _fabricControllers.values) {
      c.dispose();
    }
    for (final c in _deliveryControllers.values) {
      c.dispose();
    }
    _baseControllers.clear();
    _fabricControllers.clear();
    _deliveryControllers.clear();

    final priceMap = <String, TailorGarmentPrice>{
      for (final p in catalog.garmentPrices)
        _cellKey(p.garmentType, p.fabricQuality): p,
    };
    for (final garment in _garmentTypes) {
      for (final fabric in _fabricQualities) {
        final key = _cellKey(garment, fabric);
        final hit = priceMap[key];
        _baseControllers[key] = TextEditingController(
          text: (hit?.basePrice ?? 350).toStringAsFixed(0),
        );
        _fabricControllers[key] = TextEditingController(
          text: (hit?.fabricFee ?? 60).toStringAsFixed(0),
        );
      }
    }

    final feeMap = {
      for (final f in catalog.deliveryFees) f.cityKey: f.fee,
    };
    for (final (cityKey, _) in kDefaultDeliveryFeeCities) {
      _deliveryControllers[cityKey] = TextEditingController(
        text: (feeMap[cityKey] ?? 25).toStringAsFixed(0),
      );
    }
  }

  Future<void> _autoDetectWorkshopLocation() async {
    setState(() => _workshopLocating = true);
    await DevicePermissionPrompt.ensure(
      context,
      AppDevicePermission.location,
    );
    if (!mounted) return;
    final resolved = await DeliveryLocationService.resolve();
    if (!mounted) return;
    setState(() {
      _workshopLocating = false;
      _workshopGpsFilled = true;
      _latController.text = resolved.lat.toStringAsFixed(5);
      _lngController.text = resolved.lng.toStringAsFixed(5);
      _workshopLocationNote = resolved.statusLabel;
    });
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    final repo = ref.read(tailorPricingRepositoryProvider);
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      _snack('Enter valid workshop latitude and longitude');
      setState(() => _saving = false);
      return;
    }

    final profileResult = await repo.updateProfile(
      shopName: _shopNameController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      lat: lat,
      lng: lng,
      serviceRadiusKm: _radiusKm,
      isAcceptingOrders: _acceptingOrders,
    );
    if (!mounted) return;
    final profileFailed = profileResult.fold(
      (AppException e) {
        _snack(_errorMessage(e));
        return true;
      },
      (_) => false,
    );
    if (profileFailed) {
      setState(() => _saving = false);
      return;
    }

    final prices = <TailorGarmentPrice>[];
    for (final garment in _garmentTypes) {
      for (final fabric in _fabricQualities) {
        final key = _cellKey(garment, fabric);
        final base = double.tryParse(_baseControllers[key]?.text ?? '') ?? 0;
        final fabricFee =
            double.tryParse(_fabricControllers[key]?.text ?? '') ?? 0;
        prices.add(
          TailorGarmentPrice(
            garmentType: garment,
            fabricQuality: fabric,
            basePrice: base,
            fabricFee: fabricFee,
          ),
        );
      }
    }
    final garmentResult = await repo.saveGarmentPrices(prices);
    if (!mounted) return;
    final garmentFailed = garmentResult.fold(
      (AppException e) {
        _snack(_errorMessage(e));
        return true;
      },
      (_) => false,
    );
    if (garmentFailed) {
      setState(() => _saving = false);
      return;
    }

    final fees = kDefaultDeliveryFeeCities
        .map((entry) {
          final fee =
              double.tryParse(_deliveryControllers[entry.$1]?.text ?? '') ??
                  0;
          return TailorDeliveryFee(cityKey: entry.$1, fee: fee);
        })
        .toList(growable: false);
    final deliveryResult = await repo.saveDeliveryFees(fees);
    if (!mounted) return;
    deliveryResult.fold(
      (AppException e) => _snack(_errorMessage(e)),
      (_) async {
        await ref.read(tailorPricingCatalogProvider.notifier).reload();
        _snack('Pricing saved');
      },
    );
    if (mounted) setState(() => _saving = false);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _workshopLocationCard() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final note = _workshopLocating
        ? 'Detecting workshop location…'
        : _workshopLocationNote ??
            (lat != null && lng != null
                ? 'Workshop pin: ${lat.toStringAsFixed(4)}, '
                    '${lng.toStringAsFixed(4)}'
                : 'Set your workshop on the map for customer matching');

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
          if (_workshopLocating)
            const Padding(
              padding: EdgeInsets.only(top: 2, right: AppSpacing.sm),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 2, right: AppSpacing.sm),
              child: Icon(Icons.store_outlined, size: 20, color: AppColors.sand),
            ),
          Expanded(child: Text(note, style: AppTextStyles.bodySmall)),
          if (!_workshopLocating)
            TextButton(
              onPressed: _autoDetectWorkshopLocation,
              child: const Text('Update'),
            ),
        ],
      ),
    );
  }

  String _errorMessage(AppException error) {
    return mapAppExceptionMessage(
      error,
      fallback: 'Could not save pricing. Please try again.',
      networkMessage: 'Network issue while saving pricing. Please retry.',
      authMessage: 'Your session has expired. Please sign in again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(tailorPricingCatalogProvider);

    return catalogState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load pricing: $e')),
      data: (catalog) {
        if (_baseControllers.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _bindCatalog(catalog));
          });
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(tailorPricingCatalogProvider.notifier).reload(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text('Workshop & prices', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _sectionTitle('Workshop location'),
              TextField(
                controller: _shopNameController,
                decoration: const InputDecoration(labelText: 'Shop name'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _workshopLocationCard(),
              const SizedBox(height: AppSpacing.sm),
              Text('Service radius: ${_radiusKm.round()} km'),
              Slider(
                value: _radiusKm,
                min: 5,
                max: 150,
                divisions: 29,
                onChanged: (v) => setState(() => _radiusKm = v),
              ),
              SwitchListTile(
                title: const Text('Accepting new orders'),
                subtitle: const Text(
                  'Requires workshop coordinates and at least one price row',
                ),
                value: _acceptingOrders,
                onChanged: (v) => setState(() => _acceptingOrders = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('Garment prices (QAR)'),
              Text(
                'Base + fabric fee per garment type and fabric tier.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._garmentTypes.map(_garmentSection),
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('Delivery fees (QAR)'),
              ...kDefaultDeliveryFeeCities.map((entry) {
                final controller = _deliveryControllers[entry.$1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: entry.$2),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              LolipantsButton(
                label: 'Save pricing',
                loading: _saving,
                onPressed: _saving ? null : _saveAll,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: AppTextStyles.titleSmall),
    );
  }

  Widget _garmentSection(String garment) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.stone,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(garment, style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final fabric in _fabricQualities) ...[
              Text(fabric, style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _baseControllers[_cellKey(garment, fabric)],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Base',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller:
                          _fabricControllers[_cellKey(garment, fabric)],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Fabric fee',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
