import 'package:arrow_popup/arrow_popup.dart';
import 'package:material_ui/material_ui.dart';

typedef Place = ({
  Offset at,
  IconData icon,
  String name,
  String rating,
  String walk,
  ArrowPopupPlacement placement,
});

/// Four places on a map. Each asks for a side; the two near an edge flip.
const List<Place> places = [
  // Asks for above, but it is near the top, so it opens below.
  (
    at: Offset(66, 62),
    icon: Icons.local_cafe,
    name: 'Brown Coffee',
    rating: '4.8',
    walk: '3 min',
    placement: ArrowPopupPlacement.above,
  ),
  (
    at: Offset(240, 186),
    icon: Icons.museum,
    name: 'National Museum',
    rating: '4.7',
    walk: '8 min',
    placement: ArrowPopupPlacement.start,
  ),
  (
    at: Offset(52, 268),
    icon: Icons.park,
    name: 'Riverside Park',
    rating: '4.6',
    walk: '5 min',
    placement: ArrowPopupPlacement.end,
  ),
  // Asks for below, but it is near the bottom, so it opens above.
  (
    at: Offset(226, 384),
    icon: Icons.restaurant,
    name: 'Night Market',
    rating: '4.9',
    walk: '12 min',
    placement: ArrowPopupPlacement.below,
  ),
];

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.pinKeys});

  final List<GlobalKey> pinKeys;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: MapPainter(scheme))),
        for (final (i, place) in places.indexed)
          Positioned(
            left: place.at.dx - 16,
            top: place.at.dy - 16,
            child: Container(
              key: pinKeys[i],
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(place.icon, size: 16, color: scheme.onPrimary),
            ),
          ),
      ],
    );
  }
}

/// A quiet street map: a river, two parks, main and side streets.
class MapPainter extends CustomPainter {
  MapPainter(this.scheme);

  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = scheme.surfaceContainer,
    );

    final park = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.16);
    canvas.drawRRect(
      RRect.fromLTRBR(14, 212, 130, 320, const Radius.circular(14)),
      park,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(178, 18, 286, 110, const Radius.circular(14)),
      park,
    );

    final river = Path()
      ..moveTo(-20, h * 0.86)
      ..cubicTo(w * 0.3, h * 0.70, w * 0.55, h * 0.98, w + 20, h * 0.74);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26,
    );

    final side = Paint()
      ..color = scheme.surfaceContainerLowest
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (final x in [40.0, 112.0, 200.0, 268.0]) {
      canvas.drawLine(Offset(x, 0), Offset(x - 14, h), side);
    }
    for (final y in [40.0, 150.0, 236.0, 352.0]) {
      canvas.drawLine(Offset(0, y), Offset(w, y + 10), side);
    }

    final main = Paint()
      ..color = scheme.surfaceContainerLowest
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * 0.47), Offset(w, h * 0.40), main);
    canvas.drawLine(Offset(w * 0.52, 0), Offset(w * 0.46, h), main);
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) => oldDelegate.scheme != scheme;
}

class PlaceCard extends StatelessWidget {
  const PlaceCard(this.place, {super.key});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall!.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          style: text.titleSmall!.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
            const SizedBox(width: 2),
            Text(place.rating, style: muted),
            Text('  ·  ', style: muted),
            Icon(
              Icons.directions_walk,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
            Text(place.walk, style: muted),
          ],
        ),
      ],
    );
  }
}
