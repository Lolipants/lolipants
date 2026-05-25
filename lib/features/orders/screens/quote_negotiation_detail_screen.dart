import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/quote_negotiation.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/orders/utils/negotiation_checkout.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Customer view of a quote negotiation thread (messages + accept counter).
class QuoteNegotiationDetailScreen extends ConsumerStatefulWidget {
  const QuoteNegotiationDetailScreen({required this.negotiationId, super.key});

  final String negotiationId;

  @override
  ConsumerState<QuoteNegotiationDetailScreen> createState() =>
      _QuoteNegotiationDetailScreenState();
}

class _QuoteNegotiationDetailScreenState
    extends ConsumerState<QuoteNegotiationDetailScreen> {
  QuoteNegotiationDetail? _detail;
  bool _loading = true;
  String? _error;
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(ordersRepositoryProvider)
        .getNegotiation(widget.negotiationId);
    if (!mounted) return;
    result.fold(
      (e) => setState(() {
        _loading = false;
        _error = orderErrorMessage(e, fallback: 'Could not load negotiation.');
      }),
      (detail) => setState(() {
        _loading = false;
        _detail = detail;
      }),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await ref
        .read(ordersRepositoryProvider)
        .sendNegotiationMessage(
          negotiationId: widget.negotiationId,
          body: text,
        );
    if (!mounted) return;
    setState(() => _sending = false);
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

  Future<void> _acceptCounter() async {
    final result = await ref
        .read(ordersRepositoryProvider)
        .acceptNegotiation(widget.negotiationId);
    if (!mounted) return;
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderErrorMessage(e))),
      ),
      (detail) {
        setState(() => _detail = detail);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Price agreed — continue to payment from here or Profile → Price negotiations',
            ),
          ),
        );
      },
    );
  }

  void _checkoutWithLock(QuoteNegotiation neg) {
    final draft = ref.read(checkoutDraftProvider);
    applyNegotiationToCheckout(
      ref,
      neg,
      designName: draft?.design.name ?? 'My design',
      garmentType: draft?.design.garmentType ?? 'thobe',
      tailorName: neg.tailorName,
      shopName: neg.shopName,
    );
    context.push('/order/payment');
  }

  @override
  Widget build(BuildContext context) {
    final neg = _detail?.negotiation;
    return Scaffold(
      appBar: AppBar(title: const Text('Price negotiation')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : neg == null
                  ? const Center(child: Text('Not found'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            children: [
                              Text(
                                'List ${neg.listTotal} ${neg.currency} → '
                                'Current offer ${neg.offeredTotal} ${neg.currency}',
                                style: AppTextStyles.titleSmall,
                              ),
                              Text(neg.statusLabel, style: AppTextStyles.bodySmall),
                              const SizedBox(height: AppSpacing.md),
                              for (final m in _detail!.messages)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: Align(
                                    alignment: m.senderRole == 'customer'
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.stone,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                      ),
                                      child: Text(m.body),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (neg.status == QuoteNegotiationStatus.countered)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: LolipantsButton(
                              label:
                                  'Accept counter (${neg.offeredTotal} ${neg.currency})',
                              onPressed: _acceptCounter,
                            ),
                          ),
                        if (neg.status == QuoteNegotiationStatus.accepted)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: LolipantsButton(
                              label: 'Pay agreed price',
                              onPressed: () => _checkoutWithLock(neg),
                            ),
                          ),
                        if (neg.isActive)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              children: [
                                Expanded(
                                  child: LolipantsTextField(
                                    controller: _messageCtrl,
                                    label: 'Message',
                                  ),
                                ),
                                IconButton(
                                  onPressed: _sending ? null : _sendMessage,
                                  icon: _sending
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}
