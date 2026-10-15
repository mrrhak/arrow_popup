// Placement: `placement` picks which side of the anchor the bubble opens on.
//
// A mini design app uses each side where it makes sense: the top toolbar
// opens `below`, the left rail `end`, the right rail `start` and the
// bottom bar `above`. `start` and `end` follow the text direction, so the
// rails still open toward the canvas in right-to-left languages. The shape
// on the canvas uses `auto`, and its popup shows that an open popup updates
// when its content changes.

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/material.dart';

/// A mini design app. Each bar opens its popups on the side with room.
class PlacementDemo extends StatefulWidget {
  const PlacementDemo({super.key});

  @override
  State<PlacementDemo> createState() => _PlacementDemoState();
}

class _PlacementDemoState extends State<PlacementDemo> {
  static const _tools = [
    (icon: Icons.near_me_outlined, name: 'Select'),
    (icon: Icons.edit_outlined, name: 'Pen'),
    (icon: Icons.category_outlined, name: 'Shapes'),
    (icon: Icons.title_rounded, name: 'Text'),
  ];

  var _tool = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final divider = BorderSide(color: colorScheme.outlineVariant);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Top toolbar: popups open below.
          Container(
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(border: Border(bottom: divider)),
            child: Row(
              children: [
                for (final color in const [
                  Color(0xFFFF5F57),
                  Color(0xFFFEBC2E),
                  Color(0xFF28C840),
                ])
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Arrow Popup',
                    style: textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const _PlacementTool(
                  icon: Icons.undo_rounded,
                  name: 'Undo',
                  placement: ArrowPopupPlacement.below,
                ),
                const _PlacementTool(
                  icon: Icons.redo_rounded,
                  name: 'Redo',
                  placement: ArrowPopupPlacement.below,
                ),
                const _PlacementTool(
                  icon: Icons.file_download_outlined,
                  name: 'Export',
                  placement: ArrowPopupPlacement.below,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 196,
            child: Row(
              children: [
                // Left rail: popups open toward the canvas, after it in
                // reading order.
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(border: Border(right: divider)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final (i, tool) in _tools.indexed)
                        _PlacementTool(
                          icon: tool.icon,
                          name: tool.name,
                          placement: ArrowPopupPlacement.end,
                          selected: i == _tool,
                          onPressed: () => setState(() => _tool = i),
                        ),
                    ],
                  ),
                ),
                // Canvas: the layer uses auto.
                const Expanded(
                  child: CustomPaint(
                    painter: _DotGridPainter(),
                    child: Center(child: _CanvasLayer()),
                  ),
                ),
                // Right rail: popups open toward the canvas, before it.
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(border: Border(left: divider)),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PlacementTool(
                        icon: Icons.layers_outlined,
                        name: 'Layers',
                        placement: ArrowPopupPlacement.start,
                      ),
                      _PlacementTool(
                        icon: Icons.palette_outlined,
                        name: 'Colors',
                        placement: ArrowPopupPlacement.start,
                      ),
                      _PlacementTool(
                        icon: Icons.tune_rounded,
                        name: 'Adjust',
                        placement: ArrowPopupPlacement.start,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom bar: popups open above.
          Container(
            decoration: BoxDecoration(border: Border(top: divider)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _PlacementTool(
                  icon: Icons.zoom_out_rounded,
                  name: 'Zoom out',
                  placement: ArrowPopupPlacement.above,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('100%', style: textTheme.labelMedium),
                ),
                const _PlacementTool(
                  icon: Icons.zoom_in_rounded,
                  name: 'Zoom in',
                  placement: ArrowPopupPlacement.above,
                ),
                const _PlacementTool(
                  icon: Icons.fit_screen_outlined,
                  name: 'Fit to screen',
                  placement: ArrowPopupPlacement.above,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A toolbar button that labels itself with a popup on [placement]'s side.
class _PlacementTool extends StatelessWidget {
  const _PlacementTool({
    required this.icon,
    required this.name,
    required this.placement,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final String name;
  final ArrowPopupPlacement placement;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // The Builder's context is the button, so the arrow points at it.
    return Builder(
      builder: (context) => IconButton(
        visualDensity: VisualDensity.compact,
        isSelected: selected,
        icon: Icon(icon),
        onPressed: () {
          onPressed?.call();
          ArrowPopup.show<void>(
            context: context,
            placement: placement,
            barrierColor: Colors.transparent,
            style: ArrowPopupStyle(
              color: colorScheme.primary,
              borderRadius: 10,
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              arrowSize: const Size(12, 6),
              shadows: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            content: _PlacementLabel(
              name: name,
              placement: placement.name,
              color: colorScheme.onPrimary,
              badgeColor: colorScheme.onPrimary.withValues(alpha: 0.16),
              badgeTextColor: colorScheme.onPrimary,
            ),
          );
        },
      ),
    );
  }
}

/// A tool name with a badge naming the placement.
class _PlacementLabel extends StatelessWidget {
  const _PlacementLabel({
    required this.name,
    required this.placement,
    required this.color,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  final String name;
  final String placement;
  final Color color;
  final Color badgeColor;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            style: textTheme.labelLarge?.copyWith(color: color),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            placement,
            style: textTheme.labelSmall?.copyWith(
              color: badgeTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// A selected shape on the canvas. It has room on every side, so auto picks
/// below. Its popup is a small inspector that edits the shape while open.
class _CanvasLayer extends StatefulWidget {
  const _CanvasLayer();

  @override
  State<_CanvasLayer> createState() => _CanvasLayerState();
}

class _CanvasLayerState extends State<_CanvasLayer> {
  static const _fills = [
    [Color(0xFF06B6D4), Color(0xFF6366F1)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFF22C55E), Color(0xFF0EA5E9)],
    [Color(0xFF64748B), Color(0xFF1E293B)],
  ];
  static const _size = Size(120, 72);
  static const _radius = 12.0;

  var _fill = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    return ArrowPopup(
      barrierColor: Colors.transparent,
      style: ArrowPopupStyle(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        maxWidth: 240,
        shadows: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Rebuilt with the new fill while open, so the swatches stay in sync.
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlacementLabel(
            name: 'Rectangle 1',
            placement: 'auto',
            color: colorScheme.onSurface,
            badgeColor: colorScheme.primaryContainer,
            badgeTextColor: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LayerProp(label: 'W', value: '${_size.width.round()}'),
              const SizedBox(width: 6),
              _LayerProp(label: 'H', value: '${_size.height.round()}'),
              const SizedBox(width: 6),
              _LayerProp(
                icon: Icons.rounded_corner_rounded,
                value: '${_radius.round()}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Fill', style: muted),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, colors) in _fills.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    key: ValueKey('fill-$i'),
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _fill = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 26,
                      height: 26,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == _fill
                              ? colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: colors),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            key: const ValueKey('layer'),
            duration: const Duration(milliseconds: 200),
            width: _size.width,
            height: _size.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _fills[_fill],
              ),
            ),
            child: const Text(
              'Hello',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Selection frame and corner handles, like a design tool.
          Positioned.fill(
            left: -4,
            top: -4,
            right: -4,
            bottom: -4,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
          for (final alignment in const [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Positioned.fill(
              left: -8,
              top: -8,
              right: -8,
              bottom: -8,
              child: IgnorePointer(
                child: Align(
                  alignment: alignment,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small read-only property field in the layer inspector.
class _LayerProp extends StatelessWidget {
  const _LayerProp({this.label, this.icon, required this.value});

  final String? label;
  final IconData? icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Text(label!, style: textTheme.labelSmall?.copyWith(color: muted)),
          if (icon != null) Icon(icon, size: 12, color: muted),
          const SizedBox(width: 6),
          Text(value, style: textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x40808080);
    const spacing = 16.0;
    for (var x = spacing / 2; x < size.width; x += spacing) {
      for (var y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}
