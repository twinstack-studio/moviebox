import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/nav.dart';
import '../widgets/rewards.dart';
import 'home_shell.dart';
import 'seat_screen.dart';
import 'tickets_screen.dart';
import '../l10n.dart';
import '../services/analytics.dart';

enum PayMethod { card, jazzcash, easypaisa, raast }

extension PayMethodX on PayMethod {
  String get label => switch (this) {
    PayMethod.card => 'Debit / Credit Card',
    PayMethod.jazzcash => 'JazzCash',
    PayMethod.easypaisa => 'Easypaisa',
    PayMethod.raast => 'Raast / SadaPay / NayaPay',
  };
  String get subtitle => switch (this) {
    PayMethod.card => 'Visa, Mastercard, UnionPay, PayPak',
    PayMethod.jazzcash => 'Pay from your JazzCash wallet',
    PayMethod.easypaisa => 'Pay from your Easypaisa wallet',
    PayMethod.raast => 'Instant bank transfer via Raast ID',
  };
  IconData get icon => switch (this) {
    PayMethod.card => Icons.credit_card_rounded,
    PayMethod.jazzcash => Icons.account_balance_wallet_rounded,
    PayMethod.easypaisa => Icons.phone_android_rounded,
    PayMethod.raast => Icons.account_balance_rounded,
  };
  Color get color => switch (this) {
    PayMethod.card => Color(0xFF3B82F6),
    PayMethod.jazzcash => Color(0xFFE11D48),
    PayMethod.easypaisa => Color(0xFF22C55E),
    PayMethod.raast => Color(0xFFA855F7),
  };
}

final _phoneRe = RegExp(r'^(\+92|0092|0)3\d{9}$');
String _cleanPhone(String v) => v.replaceAll(RegExp(r'[\s-]'), '');

String? validatePhone(String? v) {
  if (v == null || !_phoneRe.hasMatch(_cleanPhone(v))) {
    return tr('Enter a valid mobile number, e.g. 03001234567');
  }
  return null;
}

class CheckoutScreen extends StatefulWidget {
  final BookingDraft draft;
  const CheckoutScreen({super.key, required this.draft});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _promo = TextEditingController();
  final _cardNo = TextEditingController();
  final _cardExp = TextEditingController();
  final _cardCvv = TextEditingController();
  final _wallet = TextEditingController();

  PayMethod _method = PayMethod.card;
  int _promoPct = 0;
  String? _promoCode;
  String? _promoError;
  bool _paying = false;
  bool _prefilled = false;

  BookingDraft get draft => widget.draft;
  int get _discount => (draft.ticketTotal * _promoPct / 100).round();
  int get _total =>
      draft.ticketTotal + draft.snackTotal + draft.fee - _discount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    Analytics.log('begin_checkout', {
      'value': _total,
      'movie': draft.movie.title,
    });
    final u = AppScope.read(context).user;
    if (u != null) {
      _name.text = u.name;
      _phone.text = u.phone;
      _email.text = u.email;
      _wallet.text = u.phone;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _email,
      _promo,
      _cardNo,
      _cardExp,
      _cardCvv,
      _wallet,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyPromo() {
    FocusScope.of(context).unfocus();
    final code = _promo.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final pct = MockCinemaRepository.promoPercent(code, draft.showtime.start);
    setState(() {
      if (pct == null) {
        _promoError = code == 'TUESDAY25'
            ? tr('TUESDAY25 is valid for Tuesday shows only')
            : tr('This code is not valid');
        _promoPct = 0;
        _promoCode = null;
        HapticFeedback.vibrate();
      } else {
        _promoError = null;
        _promoPct = pct;
        _promoCode = code;
        Analytics.log('apply_promo', {'code': code});
        HapticFeedback.mediumImpact();
      }
    });
  }

  Future<void> _pay() async {
    if (_paying) return; // guards against double taps
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(tr('Please check the highlighted fields.'))),
        );
      return;
    }
    final state = AppScope.read(context);
    final nav = Navigator.of(context);
    setState(() => _paying = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8),
              Floating(
                amplitude: 5,
                child: Icon(_method.icon, size: 44, color: _method.color),
              ),
              SizedBox(height: 16),
              LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.border,
              ),
              SizedBox(height: 20),
              Text(
                tr('Processing {0} payment…', [tr(_method.label)]),
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                tr('Please don\'t close the app.'),
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );

    PaymentResult result;
    try {
      result = await repo
          .pay(
            reference: draft.reference,
            amount: _total,
            method: _method.label,
          )
          .timeout(Duration(seconds: 45));
    } catch (_) {
      result = PaymentResult(false, 'We could not reach the payment server.');
    }
    if (!mounted) return;
    nav.pop(); // close processing dialog

    if (!result.success) {
      setState(() => _paying = false);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.error_outline, color: AppColors.warning, size: 36),
          title: Text(tr('Payment not completed')),
          content: Text(
            '${tr(result.message)}\n\n${tr('No money has been taken. If your bank shows a deduction, it is reversed automatically within 3–5 working days. Retrying will never charge you twice for this booking.')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('Close')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _pay();
              },
              child: Text(tr('Try again')),
            ),
          ],
        ),
      );
      return;
    }

    final booking = Booking(
      id: draft.reference,
      movieId: draft.movie.id,
      movieTitle: draft.movie.title,
      cinemaId: draft.cinema.id,
      cinemaName: 'Parda ${draft.cinema.name}',
      cinemaPhone: draft.cinema.phone,
      showtimeId: draft.showtime.id,
      showStart: draft.showtime.start,
      durationMin: draft.movie.durationMin,
      format: draft.showtime.format,
      screen: draft.showtime.screen,
      seats: draft.seats.map((s) => s.id).toList(),
      snacks: {
        for (final e in draft.snackQty.entries)
          if (e.value > 0)
            draft.snackCatalog.firstWhere((s) => s.id == e.key).name: e.value,
      },
      ticketTotal: draft.ticketTotal,
      snackTotal: draft.snackTotal,
      discount: _discount,
      fee: draft.fee,
      paymentMethod: _method.label,
      customerName: _name.text.trim(),
      customerPhone: _cleanPhone(_phone.text),
      createdAt: DateTime.now(),
    );
    state.addBooking(booking);
    HapticFeedback.heavyImpact();
    nav.pushAndRemoveUntil(
      appRoute(BookingSuccessScreen(bookingId: booking.id)),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = draft.showtime;
    var i = 0;
    Widget stagger(Widget child) => FadeSlideIn(index: i++, child: child);
    return PopScope(
      canPop: !_paying,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('Checkout')),
          actions: [
            HoldTimerBadge(draft: draft),
            SizedBox(width: 16),
          ],
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              stagger(
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 92,
                          child: PosterArt(
                            movie: draft.movie,
                            showTitle: false,
                            radius: 10,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                draft.movie.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Parda ${draft.cinema.name} • ${s.screen}',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${fmtDate(s.start)} • ${fmtTime(s.start)} • ${s.format}',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                tr('Seats: {0}', [
                                  draft.seats.map((e) => e.id).join(', '),
                                ]),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              stagger(_title(tr('Your details'))),
              stagger(
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: tr('Full name'),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? tr('Please enter your name')
                      : null,
                ),
              ),
              SizedBox(height: 12),
              stagger(
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: tr('Mobile number'),
                    hintText: '03XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: validatePhone,
                ),
              ),
              SizedBox(height: 12),
              stagger(
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: tr('Email (optional, for e-ticket copy)'),
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                        ? null
                        : tr('Enter a valid email');
                  },
                ),
              ),
              stagger(_title(tr('Promo code'))),
              stagger(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promo,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: tr('e.g. PARDA10'),
                          prefixIcon: Icon(Icons.local_offer_outlined),
                          errorText: _promoError,
                          helperText: _promoCode == null
                              ? null
                              : tr('{0} applied: {1}% off tickets 🎉', [
                                  _promoCode,
                                  _promoPct,
                                ]),
                          helperStyle: TextStyle(color: AppColors.success),
                        ),
                        onSubmitted: (_) => _applyPromo(),
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _applyPromo,
                        child: Text(tr('Apply')),
                      ),
                    ),
                  ],
                ),
              ),
              stagger(_title(tr('Payment method'))),
              for (final m in PayMethod.values) stagger(_methodTile(m)),
              AnimatedSize(
                duration: Duration(milliseconds: 220),
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 220),
                    child: _method == PayMethod.card
                        ? _cardFields()
                        : TextFormField(
                            key: ValueKey(_method),
                            controller: _wallet,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: _method == PayMethod.raast
                                  ? tr('Raast ID (mobile number)')
                                  : tr('{0} account number', [
                                      tr(_method.label),
                                    ]),
                              hintText: '03XXXXXXXXX',
                              prefixIcon: Icon(_method.icon),
                            ),
                            validator: validatePhone,
                          ),
                  ),
                ),
              ),
              _title(tr('Price details')),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row(
                        tr('Tickets ({0})', [draft.seats.length]),
                        pkr(draft.ticketTotal),
                      ),
                      if (draft.snackTotal > 0)
                        _row(
                          tr('Snacks ({0})', [draft.snackCount]),
                          pkr(draft.snackTotal),
                        ),
                      _row(tr('Convenience fee'), pkr(draft.fee)),
                      AnimatedSize(
                        duration: Duration(milliseconds: 250),
                        child: _discount > 0
                            ? _row(
                                tr('Discount ({0})', [_promoCode]),
                                '- ${pkr(_discount)}',
                                color: AppColors.success,
                              )
                            : SizedBox(width: double.infinity),
                      ),
                      Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr('Total payable'),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          AnimatedPrice(
                            amount: _total,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: 16,
                            color: AppColors.gold,
                          ),
                          SizedBox(width: 6),
                          Text(
                            tr('You\'ll earn {0} Parda Rewards points', [
                              rewardPoints(_total),
                            ]),
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(
                        'Secure payment. Free cancellation up to 2 hours before the show, refunded to your original payment method.',
                      ),
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          leading: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Total'),
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              AnimatedPrice(
                amount: _total,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          label: tr('Pay now'),
          loading: _paying,
          onPressed: _pay,
        ),
      ),
    );
  }

  Widget _title(String t) => Padding(
    padding: EdgeInsets.only(top: 22, bottom: 10),
    child: Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
  );

  Widget _row(String k, String v, {Color? color}) => Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(k, style: TextStyle(color: AppColors.muted)),
        ),
        Text(
          v,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _methodTile(PayMethod m) {
    final sel = _method == m;
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: PressableScale(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _method = m);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 220),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sel ? m.color.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? m.color : AppColors.border,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(m.icon, color: m.color),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(m.label),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      tr(m.subtitle),
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: Icon(
                  sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                  key: ValueKey(sel),
                  color: sel ? m.color : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardFields() {
    return Column(
      key: ValueKey('card'),
      children: [
        TextFormField(
          controller: _cardNo,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
            _CardNumberFormatter(),
          ],
          decoration: InputDecoration(
            labelText: tr('Card number'),
            prefixIcon: Icon(Icons.credit_card),
          ),
          validator: (v) {
            final d = (v ?? '').replaceAll(' ', '');
            if (d.length < 15 || !_luhn(d)) {
              return tr('Enter a valid card number');
            }
            return null;
          },
        ),
        SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _cardExp,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: tr('Expiry'),
                  hintText: 'MM/YY',
                ),
                validator: (v) {
                  final p = (v ?? '').split('/');
                  if (p.length != 2 || p[1].length != 2) return 'MM/YY';
                  final mm = int.tryParse(p[0]) ?? 0;
                  final yy = int.tryParse(p[1]) ?? 0;
                  if (mm < 1 || mm > 12) return tr('Invalid month');
                  final exp = DateTime(2000 + yy, mm + 1);
                  return exp.isAfter(DateTime.now())
                      ? null
                      : tr('Card expired');
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cardCvv,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(labelText: 'CVV'),
                validator: (v) =>
                    (v ?? '').length < 3 ? tr('Invalid CVV') : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

bool _luhn(String digits) {
  var sum = 0;
  var alt = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.parse(digits[i]);
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alt = !alt;
  }
  return sum % 10 == 0;
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = newValue.text.replaceAll(' ', '');
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = newValue.text.replaceAll('/', '');
    final t = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class BookingSuccessScreen extends StatelessWidget {
  final String bookingId;
  const BookingSuccessScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final booking = AppScope.of(context).bookingById(bookingId);
    if (booking == null) {
      return Scaffold(body: EmptyState(message: tr('Ticket not found')));
    }
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 900),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.35),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 62,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                FadeSlideIn(
                  index: 2,
                  child: Text(
                    tr('Booking confirmed!'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(height: 6),
                FadeSlideIn(
                  index: 3,
                  child: Text(
                    tr(
                      'Your ticket is saved in the Tickets tab and works offline. Show the QR code at the entrance.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                SizedBox(height: 14),
                FadeSlideIn(
                  index: 5,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          CountUp(
                            value: rewardPoints(booking.total),
                            prefix: '+',
                            duration: Duration(milliseconds: 1600),
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            tr(' Parda Rewards points'),
                            style: TextStyle(color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // The ticket "prints" down into place.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 0),
                  duration: Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) => Transform.translate(
                    offset: Offset(0, -80 * v),
                    child: Opacity(opacity: 1 - v, child: child),
                  ),
                  child: TicketCard(booking: booking),
                ),
                SizedBox(height: 20),
                FadeSlideIn(
                  index: 8,
                  child: OutlinedButton.icon(
                    onPressed: () => shareBooking(context, booking),
                    icon: Icon(Icons.share_rounded, color: AppColors.success),
                    label: Text(tr('Share with friends on WhatsApp')),
                  ),
                ),
                SizedBox(height: 12),
                FadeSlideIn(
                  index: 9,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            shellTab.value = 0;
                            Navigator.of(context).pop();
                          },
                          child: Text(tr('Back to home')),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            shellTab.value = 3;
                            Navigator.of(context).pop();
                          },
                          child: Text(tr('My tickets')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}
