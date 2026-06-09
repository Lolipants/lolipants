import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/tailor_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/models/quote_negotiation.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Tailor detail for responding to a price negotiation.
class TailorQuoteNegotiationDetailScreen extends ConsumerStatefulWidget {
  const TailorQuoteNegotiationDetailScreen({
    required this.negotiationId,
    super.key,
  });

  final String negotiationId;

  @override
  ConsumerState<TailorQuoteNegotiationDetailScreen> createState() =>
      _TailorQuoteNegotiationDetailScreenState();
}

class _TailorQuoteNegotiationDetailScreenState
    extends ConsumerState<TailorQuoteNegotiationDetailScreen> {
  QuoteNegotiationDetail? _detail;
  bool _loading = true;
  String? _error;
  final _messageCtrl = TextEditingController();
  final _counterCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _counterCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final locale = ref.read(settingsLocaleProvider);
    final result = await ref
        .read(ordersRepositoryProvider)
        .getNegotiation(widget.negotiationId);
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
      (detail) {
        _counterCtrl.text = detail.negotiation.listTotal.toString();
        setState(() {
          _loading = false;
          _detail = detail;
        });
      },
    );
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    final result = await ref
        .read(ordersRepositoryProvider)
        .acceptNegotiation(widget.negotiationId);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderErrorMessage(e))),
      ),
      (detail) => setState(() => _detail = detail),
    );
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    final result = await ref
        .read(ordersRepositoryProvider)
        .declineNegotiation(widget.negotiationId);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderErrorMessage(e))),
      ),
      (detail) => setState(() => _detail = detail),
    );
  }

  Future<void> _counter() async {
    final total = int.tryParse(_counterCtrl.text.trim());
    if (total == null) return;
    setState(() => _busy = true);
    final result = await ref.read(ordersRepositoryProvider).counterNegotiation(
          id: widget.negotiationId,
          offeredTotal: total,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderErrorMessage(e))),
      ),
      (detail) => setState(() => _detail = detail),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    final result = await ref
        .read(ordersRepositoryProvider)
        .sendNegotiationMessage(
          negotiationId: widget.negotiationId,
          body: text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderErrorMessage(e))),
      ),
      (detail) {
        _messageCtrl.clear();
        setState(() => _detail = detail);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    final neg = _detail?.negotiation;
    final canRespond =
        neg?.status == QuoteNegotiationStatus.tailorReview && !_busy;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromLocale(
            locale,
            TailorStrings.priceRequestTitle,
            TailorStrings.priceRequestTitleAr,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : neg == null
                  ? Center(
                      child: Text(
                        localizedFromLocale(
                          locale,
                          TailorStrings.notFound,
                          TailorStrings.notFoundAr,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Text(
                          TailorStrings.customerOffer(
                            neg.offeredTotal,
                            neg.currency,
                            locale,
                          ),
                          style: AppTextStyles.titleMedium,
                        ),
                        Text(
                          TailorStrings.listPrice(
                            neg.listTotal,
                            neg.currency,
                            locale,
                          ),
                          style: AppTextStyles.bodySmall,
                        ),
                        if (neg.customerNote != null &&
                            neg.customerNote!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              TailorStrings.noteLine(neg.customerNote!, locale),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        for (final m in _detail!.messages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text(
                              TailorStrings.messageLine(
                                m.senderRole,
                                m.body,
                                locale,
                              ),
                            ),
                          ),
                        const Divider(),
                        if (canRespond) ...[
                          LolipantsButton(
                            label: localizedFromLocale(
                              locale,
                              TailorStrings.acceptOffer,
                              TailorStrings.acceptOfferAr,
                            ),
                            onPressed: _accept,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LolipantsTextField(
                            controller: _counterCtrl,
                            label: localizedFromLocale(
                              locale,
                              TailorStrings.counterOfferQar,
                              TailorStrings.counterOfferQarAr,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LolipantsButton(
                            label: localizedFromLocale(
                              locale,
                              TailorStrings.sendCounter,
                              TailorStrings.sendCounterAr,
                            ),
                            variant: LolipantsButtonVariant.secondary,
                            onPressed: _counter,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LolipantsButton(
                            label: localizedFromLocale(
                              locale,
                              TailorStrings.decline,
                              TailorStrings.declineAr,
                            ),
                            variant: LolipantsButtonVariant.secondary,
                            onPressed: _decline,
                          ),
                        ],
                        if (neg.isActive) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: LolipantsTextField(
                                  controller: _messageCtrl,
                                  label: localizedFromLocale(
                                    locale,
                                    TailorStrings.reply,
                                    TailorStrings.replyAr,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _busy ? null : _sendMessage,
                                icon: const Icon(Icons.send),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
    );
  }
}
