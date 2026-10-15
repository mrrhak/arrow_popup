// Styling: `ArrowPopupStyle` sets the bubble's look.
//
// Each tile opens a different style: color, corner radius, padding, arrow
// size or no arrow, shadows, `maxWidth`, and `clipBehavior` for content
// that goes edge to edge.

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/material.dart';

class StyleDemo extends StatelessWidget {
  const StyleDemo({super.key});

  static const _white = TextStyle(color: Colors.white);

  @override
  Widget build(BuildContext context) {
    // Three tiles per row.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 2 * 12) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final popup in _popups)
              SizedBox(width: width, height: width / 1.1, child: popup),
          ],
        );
      },
    );
  }

  static const _popups = <Widget>[
    // Brand color, big radius, wide arrow and no barrier behind it.
    ArrowPopup(
      barrierColor: Colors.transparent,
      style: ArrowPopupStyle(
        color: Color(0xFF4F46E5),
        borderRadius: 18,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        arrowSize: Size(24, 12),
        maxWidth: 230,
      ),
      content: Text(
        'Any color, radius and arrow. No barrier, so the page stays '
        'bright.',
        style: _white,
      ),
      child: _StyleTile(
        icon: Icons.palette_outlined,
        label: 'Brand',
        color: Color(0xFF4F46E5),
      ),
    ),
    // Small, flat and close to the anchor, like a native tooltip.
    ArrowPopup(
      barrierColor: null,
      style: ArrowPopupStyle(
        color: Color(0xE6202124),
        borderRadius: 6,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        arrowSize: Size(10, 5),
        gap: 4,
        shadows: [],
      ),
      content: Text(
        'Copy link',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      child: _StyleTile(
        icon: Icons.link_rounded,
        label: 'Tooltip',
        color: Color(0xFF475569),
      ),
    ),
    // A colored shadow that glows around the bubble and arrow.
    ArrowPopup(
      barrierColor: Color(0x33000000),
      style: ArrowPopupStyle(
        color: Color(0xFF7C3AED),
        borderRadius: 14,
        padding: EdgeInsets.all(14),
        arrowSize: Size(18, 9),
        gap: 6,
        maxWidth: 220,
        shadows: [
          BoxShadow(color: Color(0x997C3AED), blurRadius: 24),
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: Colors.amberAccent),
          SizedBox(width: 10),
          Flexible(
            child: Text('Pro unlocked! Enjoy every feature.', style: _white),
          ),
        ],
      ),
      child: _StyleTile(
        icon: Icons.auto_awesome_outlined,
        label: 'Glow',
        color: Color(0xFF7C3AED),
      ),
    ),
    // Edge-to-edge content, clipped to the rounded bubble.
    ArrowPopup(
      style: ArrowPopupStyle(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        clipBehavior: Clip.antiAlias,
        maxWidth: 240,
      ),
      content: _ProfileCard(),
      child: _StyleTile(
        icon: Icons.badge_outlined,
        label: 'Card',
        color: Color(0xFF0891B2),
      ),
    ),
    // An oversized arrow that really points.
    ArrowPopup(
      style: ArrowPopupStyle(
        color: Color(0xFFF59E0B),
        borderRadius: 12,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        arrowSize: Size(36, 18),
      ),
      content: Text(
        'Over here!',
        style: TextStyle(color: Color(0xFF451A03), fontWeight: FontWeight.w600),
      ),
      child: _StyleTile(
        icon: Icons.near_me_outlined,
        label: 'Big arrow',
        color: Color(0xFFD97706),
      ),
    ),
    // No arrow and a wider gap, like a floating notice.
    ArrowPopup(
      style: ArrowPopupStyle(
        color: Color(0xFFDC2626),
        showArrow: false,
        borderRadius: 999,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        gap: 8,
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('You are offline', style: _white),
        ],
      ),
      child: _StyleTile(
        icon: Icons.campaign_outlined,
        label: 'No arrow',
        color: Color(0xFFDC2626),
      ),
    ),
  ];
}

/// A plain tile, so ArrowPopup gets the tap.
class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Without padding, clipBehavior keeps this inside the rounded corners.
        Container(
          height: 72,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0891B2), Color(0xFF4F46E5)],
            ),
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(12),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Text('JL'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jamie Lee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Text(
            'Flutter developer. Builds packages with arrows.',
            style: textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '128 followers',
                  style: textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FilledButton.tonal(
                onPressed: () => ArrowPopup.close(context),
                child: const Text('Follow'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
