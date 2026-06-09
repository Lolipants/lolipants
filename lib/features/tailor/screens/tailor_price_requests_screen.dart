import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/tailor_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/models/quote_negotiation.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Tailor inbox for inbound customer price requests.
class TailorPriceRequestsScreen extends ConsumerStatefulWidget {
  const TailorPriceRequestsScreen({super.key});

  @override
  ConsumerState<TailorPriceRequestsScreen> createState() =>
      _TailorPriceRequestsScreenState();
}

class _TailorPriceRequestsScreenState
    extends ConsumerState<TailorPriceRequestsScreen> {
  List<QuoteNegotiation> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final locale = ref.read(settingsLocaleProvider);
    final result =
        await ref.read(ordersRepositoryProvider).listTailorNegotiations();
    if (!mounted) return;
    result.fold(
      (e) => setState(() {
        _loading = false;
        _error = orderErrorMessage(
          e,
          fallback: localizedFromLocale(
            locale,
            TailorStrings.couldNotLoadRequests,
            TailorStrings.couldNotLoadRequestsAr,
          ),
        );
      }),
      (items) => setState(() {
        _loading = false;
        _items = items;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : _error != null
              ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(_error!),
                    ),
                  ],
                )
              : _items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            localizedFromLocale(
                              locale,
                              TailorStrings.noPriceRequests,
                              TailorStrings.noPriceRequestsAr,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final n = _items[index];
                        return Card(
                          color: AppColors.stone,
                          child: ListTile(
                            title: Text(
                              TailorStrings.offerTotal(
                                n.offeredTotal,
                                n.currency,
                                locale,
                              ),
                              style: AppTextStyles.titleSmall,
                            ),
                            subtitle: Text(
                              TailorStrings.listTotalStatus(
                                n.listTotal,
                                n.statusLabel,
                                locale,
                              ),
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '/tailor/price-requests/${n.id}',
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
