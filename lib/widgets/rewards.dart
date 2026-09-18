import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'animations.dart';
import '../l10n.dart';

/// MovieBox Rewards: 1 point for every Rs. 100 paid in the app.
int rewardPoints(int amountPaid) => amountPaid ~/ 100;

class RewardTier {
  final String name;
  final int minPoints;
  final Color color;
  final List<String> perks;
  RewardTier(this.name, this.minPoints, this.color, this.perks);
}

final rewardTiers = [
  RewardTier('Silver', 0, Color(0xFFB8C0CC), [
    '1 point for every Rs. 100 spent',
    'Free regular popcorn in your birthday month',
  ]),
  RewardTier('Gold', 500, AppColors.gold, [
    'Everything in Silver',
    '10% off all snacks',
    'Early access to blockbuster bookings',
  ]),
  RewardTier('Platinum', 1500, AppColors.platinum, [
    'Everything in Gold',
    'One free recliner upgrade every month',
    'Priority support line',
  ]),
];

int totalPoints(AppState state) => state.bookings
    .where((b) => b.status == BookingStatus.confirmed)
    .fold(0, (sum, b) => sum + rewardPoints(b.total));

RewardTier tierFor(int points) =>
    rewardTiers.lastWhere((t) => points >= t.minPoints);

RewardTier? nextTier(int points) {
  for (final t in rewardTiers) {
    if (t.minPoints > points) return t;
  }
  return null;
}

class RewardsCard extends StatelessWidget {
  const RewardsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final points = totalPoints(AppScope.of(context));
    final tier = tierFor(points);
    final next = nextTier(points);
    final progress = next == null
        ? 1.0
        : (points - tier.minPoints) / (next.minPoints - tier.minPoints);
    return Padding(
      padding: EdgeInsets.only(top: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showTiers(context, points),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [tier.color.withValues(alpha: 0.22), AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: tier.color.withValues(alpha: 0.45)),
            ),
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: tier.color,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('MovieBox Rewards'),
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              tr('{0} member', [tr(tier.name)]),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: tier.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CountUp(
                        value: points,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(tr('pts'), style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                  SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                      duration: Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        color: tier.color,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    next == null
                        ? tr('Top tier reached — enjoy your perks!')
                        : tr('{0} points to {1} • Tap to see perks', [
                            next.minPoints - points,
                            tr(next.name),
                          ]),
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTiers(BuildContext context, int points) {
    final current = tierFor(points);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              tr('MovieBox Rewards'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 4),
            Text(
              tr(
                'Earn 1 point for every Rs. 100 you spend on tickets and snacks in the app.',
              ),
              style: TextStyle(color: AppColors.muted),
            ),
            SizedBox(height: 16),
            for (final (i, t) in rewardTiers.indexed)
              FadeSlideIn(
                index: i,
                child: Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: t == current
                        ? t.color.withValues(alpha: 0.12)
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: t == current ? t.color : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: t.color),
                          SizedBox(width: 8),
                          Text(
                            tr(t.name),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: t.color,
                            ),
                          ),
                          Spacer(),
                          Text(
                            t == current
                                ? tr('Your tier')
                                : tr('from {0} pts', [t.minPoints]),
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      for (final perk in t.perks)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: t.color,
                              ),
                              SizedBox(width: 8),
                              Expanded(child: Text(tr(perk))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
