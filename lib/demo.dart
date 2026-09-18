import 'package:flutter/material.dart';

import 'l10n.dart';
import 'theme.dart';

/// This build is a portfolio demo: payments are simulated and nothing is
/// charged. Checkout accepts only the demo card below, so nobody types in
/// real card details.
const bool kDemoMode = true;

const String kDemoCardNumber = '4242 4242 4242 4242';
const String kDemoCardExpiry = '12/30';
const String kDemoCardCvv = '123';
const String kDemoWallet = '03001234567';

/// Thin strip shown above every screen of the web demo.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF59E0B),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Colors.black,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tr('Demo app · No real payments · Built by TwinStack Studio'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notice at the top of the payment section, with a button that fills in
/// the demo payment details.
class DemoPaymentNotice extends StatelessWidget {
  final VoidCallback onUseDemoDetails;
  const DemoPaymentNotice({super.key, required this.onUseDemoDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 18,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Demo app: no real payments'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tr(
              'Nothing is charged and no details leave your device. '
              'Only the demo card {0} is accepted.',
              [kDemoCardNumber],
            ),
            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onUseDemoDetails,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: Text(tr('Use demo details')),
          ),
        ],
      ),
    );
  }
}

/// Web demo layout: the demo banner on top, and the app kept at phone width
/// in the middle of wide screens.
class DemoWebFrame extends StatelessWidget {
  final Widget child;
  const DemoWebFrame({super.key, required this.child});

  static const double _maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DemoBanner(),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFF050507),
            child: LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth.clamp(0.0, _maxWidth);
                final media = MediaQuery.of(context);
                return Center(
                  child: SizedBox(
                    width: width,
                    // Screens that read the screen size see the phone frame,
                    // not the whole browser window.
                    child: MediaQuery(
                      data: media
                          .removePadding(removeTop: true)
                          .copyWith(size: Size(width, box.maxHeight)),
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
