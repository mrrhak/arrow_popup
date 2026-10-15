import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/material.dart';

class PostScreen extends StatelessWidget {
  const PostScreen({
    super.key,
    required this.likeKey,
    required this.commentKey,
    required this.shareKey,
    this.bottomSpace = 84,
  });

  final GlobalKey likeKey;
  final GlobalKey commentKey;
  final GlobalKey shareKey;

  /// Room below the action row, for popups that open below it.
  final double bottomSpace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget action(Key? key, IconData icon, String? count, [Color? color]) {
      return Padding(
        key: key,
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color ?? scheme.onSurfaceVariant),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(count, style: text.labelLarge),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.tertiaryContainer,
                child: Text(
                  'K',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kimhak', style: text.titleSmall),
                  Text(
                    'Package author · Just now',
                    style: text.bodySmall!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primaryContainer, scheme.tertiaryContainer],
              ),
            ),
            child: Icon(
              Icons.landscape_outlined,
              size: 56,
              color: scheme.onPrimaryContainer.withValues(alpha: 0.5),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              ArrowPopup<void>(
                key: likeKey,
                trigger: ArrowPopupTrigger.longPress,
                placement: ArrowPopupPlacement.above,
                barrierColor: null,
                style: ArrowPopupStyle.of(context).copyWith(
                  color: () => scheme.surfaceContainerLowest,
                  borderRadius: 30,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  arrowSize: const Size(14, 7),
                ),
                content: const Reactions(),
                child: action(
                  null,
                  Icons.favorite,
                  '128',
                  const Color(0xFFE91E63),
                ),
              ),
              action(commentKey, Icons.chat_bubble_outline, '3'),
              const Spacer(),
              action(shareKey, Icons.share_outlined, null),
            ],
          ),
        ),
        SizedBox(height: bottomSpace),
      ],
    );
  }
}

/// The reactions a long press on the like button offers.
class Reactions extends StatelessWidget {
  const Reactions({super.key});

  static const _size = 34.0;

  @override
  Widget build(BuildContext context) {
    Widget circle(IconData icon, List<Color> colors) => Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: _size * 0.56),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        circle(Icons.thumb_up, const [Color(0xFF1FA8FF), Color(0xFF0866FF)]),
        circle(Icons.favorite, const [Color(0xFFFF6B81), Color(0xFFE41E3F)]),
        for (final face in Face.values)
          CustomPaint(
            size: const Size.square(_size),
            painter: FacePainter(face),
          ),
      ],
    );
  }
}

enum Face { haha, wow, sad, angry }

/// A reaction face: a gradient circle with simple dark features.
class FacePainter extends CustomPainter {
  const FacePainter(this.face);

  final Face face;

  static const _ink = Color(0xFF5B3A0E);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    Rect oval(double x, double y, double w, double h) =>
        Rect.fromCenter(center: p(x, y), width: w * s, height: h * s);
    final stroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 0.06 * s;
    final fill = Paint()..color = _ink;

    final bounds = Offset.zero & size;
    canvas.drawOval(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: face == Face.angry
              ? const [Color(0xFFE8452C), Color(0xFFFFD25A)]
              : const [Color(0xFFFFE36E), Color(0xFFF7B12A)],
        ).createShader(bounds),
    );

    switch (face) {
      case Face.haha:
        // Squeezed-shut eyes and a wide open mouth with a tongue.
        canvas.drawPath(
          Path()
            ..moveTo(0.24 * s, 0.28 * s)
            ..lineTo(0.38 * s, 0.35 * s)
            ..lineTo(0.24 * s, 0.42 * s),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(0.76 * s, 0.28 * s)
            ..lineTo(0.62 * s, 0.35 * s)
            ..lineTo(0.76 * s, 0.42 * s),
          stroke,
        );
        final mouth = Path()
          ..moveTo(0.2 * s, 0.52 * s)
          ..lineTo(0.8 * s, 0.52 * s)
          ..cubicTo(0.8 * s, 0.8 * s, 0.64 * s, 0.88 * s, 0.5 * s, 0.88 * s)
          ..cubicTo(0.36 * s, 0.88 * s, 0.2 * s, 0.8 * s, 0.2 * s, 0.52 * s)
          ..close();
        canvas.drawPath(mouth, fill);
        canvas.save();
        canvas.clipPath(mouth);
        canvas.drawOval(
          oval(0.5, 0.88, 0.4, 0.26),
          Paint()..color = const Color(0xFFF2506A),
        );
        canvas.restore();
      case Face.wow:
        // Raised brows, round eyes and an open mouth.
        stroke.strokeWidth = 0.05 * s;
        canvas.drawPath(
          Path()
            ..moveTo(0.22 * s, 0.25 * s)
            ..quadraticBezierTo(0.31 * s, 0.14 * s, 0.41 * s, 0.22 * s),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(0.78 * s, 0.25 * s)
            ..quadraticBezierTo(0.69 * s, 0.14 * s, 0.59 * s, 0.22 * s),
          stroke,
        );
        canvas.drawOval(oval(0.33, 0.4, 0.12, 0.17), fill);
        canvas.drawOval(oval(0.67, 0.4, 0.12, 0.17), fill);
        canvas.drawOval(oval(0.5, 0.71, 0.26, 0.32), fill);
      case Face.sad:
        // Brows raised in the middle, a frown and a tear.
        stroke.strokeWidth = 0.05 * s;
        canvas.drawLine(p(0.22, 0.33), p(0.4, 0.25), stroke);
        canvas.drawLine(p(0.78, 0.33), p(0.6, 0.25), stroke);
        canvas.drawOval(oval(0.34, 0.45, 0.11, 0.13), fill);
        canvas.drawOval(oval(0.66, 0.45, 0.11, 0.13), fill);
        canvas.drawPath(
          Path()
            ..moveTo(0.34 * s, 0.77 * s)
            ..quadraticBezierTo(0.5 * s, 0.62 * s, 0.66 * s, 0.77 * s),
          stroke,
        );
        final tear = Paint()..color = const Color(0xFF4AA8FF);
        canvas.drawCircle(p(0.27, 0.68), 0.065 * s, tear);
        canvas.drawPath(
          Path()
            ..moveTo(0.27 * s, 0.5 * s)
            ..lineTo(0.208 * s, 0.665 * s)
            ..lineTo(0.332 * s, 0.665 * s)
            ..close(),
          tear,
        );
      case Face.angry:
        // Brows pulled down to the middle and a tight frown.
        stroke.strokeWidth = 0.07 * s;
        canvas.drawLine(p(0.2, 0.4), p(0.42, 0.48), stroke);
        canvas.drawLine(p(0.8, 0.4), p(0.58, 0.48), stroke);
        canvas.drawOval(oval(0.35, 0.58, 0.1, 0.1), fill);
        canvas.drawOval(oval(0.65, 0.58, 0.1, 0.1), fill);
        stroke.strokeWidth = 0.055 * s;
        canvas.drawPath(
          Path()
            ..moveTo(0.38 * s, 0.8 * s)
            ..quadraticBezierTo(0.5 * s, 0.73 * s, 0.62 * s, 0.8 * s),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) => oldDelegate.face != face;
}
