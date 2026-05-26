import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constant.dart';
import '../../core/localization.dart';
import '../../controllers/segment_controller.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String tripRoute;
  final int seats;
  final VoidCallback? onSuccess;
  final int? bookingId;
  final String? token;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.tripRoute,
    this.seats = 1,
    this.onSuccess,
    this.bookingId,
    this.token,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _Method { cash, card, wallet }
enum _Stage { method, details, processing, success, failed }

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final _segCtl = SegmentController();

  _Method _method = _Method.cash;
  _Stage _stage = _Stage.method;
  _Method? _expandedWhy;
  final _cardNumCtl = TextEditingController(text: '4242 4242 4242 4242');
  final _cardHolderCtl = TextEditingController(text: 'SMART RIDE');
  final _expiryCtl = TextEditingController(text: '12/28');
  final _cvvCtl = TextEditingController(text: '123');
  final _formKey = GlobalKey<FormState>();
  late AnimationController _spinCtl;
  late Animation<double> _spinAnim;
  late AnimationController _checkCtl;
  late Animation<double> _checkAnim;
  final double _walletBalance = 8.75;

  int _processingStep = 0;
  late String _txnId;
  static const int _kStepCount = 4;
  @override
  void initState() {
    super.initState();
    _txnId = _generateTxnId();

    _spinCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _spinAnim = Tween(begin: 0.0, end: 1.0).animate(_spinCtl);

    _checkCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkAnim = CurvedAnimation(parent: _checkCtl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _spinCtl.dispose();
    _checkCtl.dispose();
    _cardNumCtl.dispose();
    _cardHolderCtl.dispose();
    _expiryCtl.dispose();
    _cvvCtl.dispose();
    super.dispose();
  }

  String _generateTxnId() {
    final rng = math.Random();
    final code = List.generate(8, (_) => rng.nextInt(10)).join();
    return 'TXN-SR-$code';
  }
  String _stepLabel(int i, S s) {
    switch (i) {
      case 0: return s.payStep1;
      case 1: return s.payStep2;
      case 2: return s.payStep3;
      default: return s.payStep4;
    }
  }

  Future<void> _startProcessing() async {
    HapticFeedback.lightImpact();

    if (_method == _Method.card) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }
    if (_method == _Method.wallet && _walletBalance < widget.amount) {
      AppToast.show(context, S.of(context).insufficientBalance, error: true);
      return;
    }
    _txnId = _generateTxnId();
    final willFail = math.Random().nextDouble() < 0.20;

    setState(() {
      _stage = _Stage.processing;
      _processingStep = 0;
    });

    for (int i = 0; i < _kStepCount; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _processingStep = i);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _processingStep = _kStepCount);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _spinCtl.stop();

    if (willFail) {
      HapticFeedback.heavyImpact();
      setState(() => _stage = _Stage.failed);
    } else {
      setState(() => _stage = _Stage.success);
      _checkCtl.forward();
      HapticFeedback.heavyImpact();
      final bid   = widget.bookingId;
      final token = widget.token;
      if (bid != null && token != null) {
        final methodStr = switch (_method) {
          _Method.cash   => 'cash',
          _Method.card   => 'card',
          _Method.wallet => 'wallet',
        };
        _segCtl.savePaymentMethod(
          token:     token,
          bookingId: bid,
          method:    methodStr,
        );
      }

      widget.onSuccess?.call();
    }
  }
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: switch (_stage) {
                _Stage.method => _methodPage(s),
                _Stage.details => _detailsPage(s),
                _Stage.processing => _processingPage(s),
                _Stage.success => _successPage(s),
                _Stage.failed => _failedPage(s),
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _methodPage(S s) {
    return Column(
      key: const ValueKey('method'),
      children: [
        _appBar(s.paymentTitle, canPop: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _orderSummary(s),
              const SizedBox(height: 20),
              Text(s.paymentMethod,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6)),
              const SizedBox(height: 10),
              _methodTile(
                icon: Icons.payments_rounded,
                color: AppColors.emerald,
                title: s.payByCash,
                caption: s.cashCaption,
                value: _Method.cash,
                whyText:
                    'Best if you prefer not to share card details online. '
                    'Pay the driver directly in cash when you board. '
                    'No processing fees, no waiting — just hand it over.',
                s: s,
              ),
              const SizedBox(height: 10),
              _methodTile(
                icon: Icons.credit_card_rounded,
                color: AppColors.primary,
                title: s.payByCard,
                caption: s.cardCaption,
                value: _Method.card,
                whyText:
                    'Safest and most convenient option. Your payment is held '
                    'in escrow and only released to the driver after your trip '
                    'completes — so you\'re always protected. Supports Visa & Mastercard.',
                s: s,
              ),
              const SizedBox(height: 10),
              _methodTile(
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.sky,
                title: s.payByWallet,
                caption:
                    '${s.walletBalance}: ${_walletBalance.toStringAsFixed(2)} ${s.currency}',
                value: _Method.wallet,
                whyText:
                    'Instant, one-tap payment using your Smart Ride wallet balance. '
                    'Refunds from cancelled trips land here automatically — '
                    'making it the fastest way to pay for your next ride.',
                s: s,
                disabled: _walletBalance < widget.amount,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: _method == _Method.cash ? s.confirm : s.next,
                icon: _method == _Method.cash
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (_method == _Method.cash) {
                    _startProcessing();
                  } else {
                    setState(() => _stage = _Stage.details);
                  }
                },
              ),
              const SizedBox(height: 16),
              _securedBadge(s),
            ],
          ),
        ),
      ],
    );
  }

  Widget _methodTile({
    required IconData icon,
    required Color color,
    required String title,
    required String caption,
    required String whyText,
    required _Method value,
    required S s,
    bool disabled = false,
  }) {
    final selected = _method == value;
    final whyOpen = _expandedWhy == value;

    return GestureDetector(
      onTap: disabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() => _method = value);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppShadows.card() : [],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: disabled
                          ? AppColors.surfaceMuted
                          : color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon,
                        color: disabled ? AppColors.textMuted : color,
                        size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: disabled
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(caption,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.3)),
                        if (disabled)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(s.insufficientBalance,
                                style: const TextStyle(
                                    color: AppColors.rose,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.borderStrong,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 13)
                        : null,
                  ),
                ],
              ),
            ),
            if (!disabled)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() =>
                      _expandedWhy = whyOpen ? null : value);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: whyOpen
                        ? color.withOpacity(0.08)
                        : AppColors.surfaceAlt.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        whyOpen
                            ? Icons.help_rounded
                            : Icons.help_outline_rounded,
                        color: color,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        whyOpen ? 'Hide explanation' : 'Why choose this?',
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Icon(
                        whyOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: color,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: whyOpen
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.06),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_rounded,
                              color: color.withOpacity(0.7), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              whyText,
                              style: TextStyle(
                                  color: AppColors.textSecondary
                                      .withOpacity(0.9),
                                  fontSize: 12.5,
                                  height: 1.55),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsPage(S s) {
    return Column(
      key: const ValueKey('details'),
      children: [
        _appBar(s.paymentTitle,
            canPop: true,
            onBack: () => setState(() => _stage = _Stage.method)),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _orderSummary(s),
                const SizedBox(height: 20),
                if (_method == _Method.card) ..._cardFields(s),
                if (_method == _Method.wallet) ..._walletDetails(s),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: s.payNow,
                  icon: Icons.lock_rounded,
                  onTap: _startProcessing,
                ),
                const SizedBox(height: 16),
                _securedBadge(s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _cardFields(S s) {
    return [
      Text(s.payByCard,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6)),
      const SizedBox(height: 10),

      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.amberSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.science_rounded,
                color: AppColors.amber, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.paySimMode,
                      style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(s.paySimCard,
                      style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 11,
                          height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      _cardPreview(),
      const SizedBox(height: 16),

      _field(
        controller: _cardNumCtl,
        label: s.cardNumber,
        hint: '0000  0000  0000  0000',
        icon: Icons.credit_card_rounded,
        keyboardType: TextInputType.number,
        maxLength: 19,
        inputFormatters: [_CardNumberFormatter()],
        validator: (v) =>
            (v == null || v.replaceAll(' ', '').length < 16)
                ? 'Enter a valid 16-digit card number'
                : null,
      ),
      const SizedBox(height: 10),
      _field(
        controller: _cardHolderCtl,
        label: s.cardHolder,
        hint: 'Name on card',
        icon: Icons.person_rounded,
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Enter cardholder name'
            : null,
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _field(
              controller: _expiryCtl,
              label: s.expiryDate,
              hint: 'MM/YY',
              icon: Icons.calendar_month_rounded,
              keyboardType: TextInputType.number,
              maxLength: 5,
              inputFormatters: [_ExpiryFormatter()],
              validator: (v) =>
                  (v == null || v.length < 5) ? 'MM/YY required' : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _field(
              controller: _cvvCtl,
              label: s.cvv,
              hint: '•••',
              icon: Icons.lock_outline_rounded,
              keyboardType: TextInputType.number,
              maxLength: 3,
              obscure: true,
              validator: (v) =>
                  (v == null || v.length < 3) ? 'CVV required' : null,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _cardPreview() {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0EA5A4), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.primary(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.sim_card_rounded,
                    color: Colors.white, size: 14),
              ),
              const Spacer(),
              Text('SMART PAY',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5)),
            ],
          ),
          const Spacer(),
          // Live card number display
          ValueListenableBuilder(
            valueListenable: _cardNumCtl,
            builder: (_, val, __) {
              final raw = val.text.replaceAll(' ', '');
              final padded = raw.padRight(16, '•');
              final groups = [
                padded.substring(0, 4),
                padded.substring(4, 8),
                padded.substring(8, 12),
                padded.substring(12, 16),
              ];
              return Text(groups.join('   '),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2));
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ValueListenableBuilder(
                valueListenable: _cardHolderCtl,
                builder: (_, val, __) => Text(
                  val.text.isEmpty ? 'CARDHOLDER' : val.text.toUpperCase(),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1),
                ),
              ),
              const Spacer(),
              ValueListenableBuilder(
                valueListenable: _expiryCtl,
                builder: (_, val, __) => Text(
                  val.text.isEmpty ? 'MM/YY' : val.text,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _walletDetails(S s) {
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: AppDecor.card(bg: AppColors.skySoft),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.sky, size: 36),
            const SizedBox(height: 10),
            Text(s.payByWallet,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
                '${s.walletBalance}: ${_walletBalance.toStringAsFixed(2)} ${s.currency}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.totalAmount,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text('${widget.amount.toStringAsFixed(2)} ${s.currency}',
                      style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        hintStyle:
            const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.rose, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.rose, width: 1.8),
        ),
      ),
    );
  }

  Widget _processingPage(S s) {
    return Center(
      key: const ValueKey('processing'),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _spinAnim,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: AppShadows.primary(),
                ),
                child: const Icon(Icons.sync_rounded,
                    color: Colors.white, size: 38),
              ),
            ),
            const SizedBox(height: 30),
            Text(s.processing,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_txnId,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 28),
            ...List.generate(_kStepCount, (i) {
              final done = i < _processingStep;
              final current = i == _processingStep;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppColors.emerald
                            : current
                                ? AppColors.primary.withOpacity(0.15)
                                : AppColors.surfaceAlt,
                        border: Border.all(
                          color: done
                              ? AppColors.emerald
                              : current
                                  ? AppColors.primary
                                  : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 13)
                          : current
                              ? const Icon(Icons.circle,
                                  color: AppColors.primary, size: 8)
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _stepLabel(i, s),
                      style: TextStyle(
                        color: done
                            ? AppColors.emerald
                            : current
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                        fontSize: 13.5,
                        fontWeight: current
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _successPage(S s) {
    return Center(
      key: const ValueKey('success'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _checkAnim,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.emeraldSoft,
                    border:
                        Border.all(color: AppColors.emerald, width: 3),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.emerald, size: 48),
                ),
              ),
              const SizedBox(height: 20),
              Text(s.paymentSuccess,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(s.paymentSuccessBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5)),
              const SizedBox(height: 24),
              // Full receipt
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppDecor.card(bg: AppColors.emeraldSoft),
                child: Column(
                  children: [
                    _receiptRow('Route', widget.tripRoute),
                    const Divider(height: 16, color: AppColors.border),
                    _receiptRow(
                        'Seats', '${widget.seats} seat${widget.seats > 1 ? 's' : ''}'),
                    const Divider(height: 16, color: AppColors.border),
                    _receiptRow(s.totalAmount,
                        '${widget.amount.toStringAsFixed(2)} ${s.currency}',
                        bold: true, color: AppColors.emerald),
                    const Divider(height: 16, color: AppColors.border),
                    _receiptRow('Method', switch (_method) {
                      _Method.cash => s.payByCash,
                      _Method.card => s.payByCard,
                      _Method.wallet => s.payByWallet,
                    }),
                    const Divider(height: 16, color: AppColors.border),
                    _receiptRow('Transaction ID', _txnId),
                    const Divider(height: 16, color: AppColors.border),
                    _receiptRow('Status', '✅  Confirmed'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: s.done,
                icon: Icons.check_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      ],
    );
  }

  Widget _failedPage(S s) {
    return Center(
      key: const ValueKey('failed'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.roseSoft,
                border: Border.all(color: AppColors.rose, width: 3),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.rose, size: 48),
            ),
            const SizedBox(height: 24),
            Text(s.paymentFailed,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(s.paymentFailedBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5)),
            const SizedBox(height: 28),
            PrimaryButton(
              label: s.tryAgain,
              icon: Icons.refresh_rounded,
              onTap: () {
                _spinCtl.repeat();
                setState(() {
                  _stage = _Stage.method;
                  _processingStep = 0;
                });
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: s.cancel,
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBar(String title, {bool canPop = false, VoidCallback? onBack}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
      child: Row(
        children: [
          if (canPop)
            GestureDetector(
              onTap: onBack ?? () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: AppDecor.outline(),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 16),
              ),
            ),
          if (canPop) const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _orderSummary(S s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.primary(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(s.orderSummary,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.tripRoute,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text('${widget.seats} seat${widget.seats > 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(s.totalAmount,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${widget.amount.toStringAsFixed(2)} ${s.currency}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _securedBadge(S s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 13),
        const SizedBox(width: 5),
        Text(s.securedBy,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buf.write('/');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
