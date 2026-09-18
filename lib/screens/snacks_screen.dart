import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repository.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/nav.dart';
import 'checkout_screen.dart';
import 'seat_screen.dart';
import '../l10n.dart';
import '../services/analytics.dart';

class SnacksScreen extends StatefulWidget {
  final BookingDraft draft;
  const SnacksScreen({super.key, required this.draft});

  @override
  State<SnacksScreen> createState() => _SnacksScreenState();
}

class _SnacksScreenState extends State<SnacksScreen> {
  String _category = 'All';
  BookingDraft get draft => widget.draft;

  void _change(SnackItem item, int delta) {
    final q = (draft.snackQty[item.id] ?? 0) + delta;
    if (q > 10) return;
    if (delta > 0) Analytics.log('add_snack', {'item': item.name});
    HapticFeedback.selectionClick();
    setState(() {
      if (q <= 0) {
        draft.snackQty.remove(item.id);
      } else {
        draft.snackQty[item.id] = q;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Add snacks')),
        actions: [
          HoldTimerBadge(draft: draft),
          SizedBox(width: 16),
        ],
      ),
      body: AsyncView<List<SnackItem>>(
        load: repo.snacks,
        builder: (context, items) {
          draft.snackCatalog = items;
          final cats = ['All', ...items.map((e) => e.category).toSet()];
          final list = _category == 'All'
              ? items
              : items.where((e) => e.category == _category).toList();
          return ListView(
            padding: EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [AppColors.goldTint, AppColors.surface],
                    ),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: AppColors.gold),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr(
                            'Pre-order and skip the queue — collect at the counter by showing your ticket QR.',
                          ),
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final c in cats)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(tr(c)),
                          selected: _category == c,
                          showCheckmark: false,
                          labelStyle: appTextStyle(
                            color: _category == c
                                ? Colors.white
                                : AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              for (final (i, item) in list.indexed)
                FadeSlideIn(
                  key: ValueKey('$_category-${item.id}'),
                  index: i,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 6, 20, 6),
                    child: _SnackTile(
                      item: item,
                      qty: draft.snackQty[item.id] ?? 0,
                      onAdd: () => _change(item, 1),
                      onRemove: () => _change(item, -1),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomActionBar(
        leading: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.snackCount == 0
                  ? tr(draft.seats.length == 1 ? '{0} ticket' : '{0} tickets', [
                      draft.seats.length,
                    ])
                  : tr(
                      draft.seats.length == 1
                          ? '{0} ticket + {1} snacks'
                          : '{0} tickets + {1} snacks',
                      [draft.seats.length, draft.snackCount],
                    ),
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            AnimatedPrice(
              amount: draft.ticketTotal + draft.snackTotal,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        label: draft.snackCount == 0 ? tr('Skip') : tr('Continue'),
        onPressed: () =>
            Navigator.of(context).push(appRoute(CheckoutScreen(draft: draft))),
      ),
    );
  }
}

class _SnackTile extends StatelessWidget {
  final SnackItem item;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _SnackTile({
    required this.item,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: qty > 0
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.35),
                  AppColors.primary.withValues(alpha: 0.25),
                ],
              ),
            ),
            child: Icon(item.icon, color: Colors.white, size: 28),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(item.name),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                SizedBox(height: 2),
                Text(
                  tr(item.description),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  pkr(item.price),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          if (qty == 0)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: Size(64, 38),
                side: BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
              onPressed: onAdd,
              child: Text(tr('Add')),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemove,
                    icon: Icon(Icons.remove, color: Colors.white, size: 18),
                  ),
                  Text(
                    '$qty',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onAdd,
                    icon: Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
