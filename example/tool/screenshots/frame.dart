import 'package:material_ui/material_ui.dart';

/// A caption on the left and a phone-sized screen on the right.
class Poster extends StatelessWidget {
  const Poster({
    super.key,
    required this.title,
    required this.subtitle,
    required this.screen,
    this.glow = false,
  });

  final String title;
  final String subtitle;
  final Widget screen;

  /// Soft colored light behind the phone, with a lit edge on it.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: DecoratedBox(
        decoration: glow
            ? BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.55, -0.1),
                  radius: 0.75,
                  colors: [
                    scheme.primary.withValues(alpha: dark ? 0.34 : 0.20),
                    scheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              )
            : const BoxDecoration(),
        child: DecoratedBox(
          decoration: glow
              ? BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.0, 1.1),
                    radius: 0.8,
                    colors: [
                      scheme.tertiary.withValues(alpha: dark ? 0.16 : 0.12),
                      scheme.tertiary.withValues(alpha: 0.0),
                    ],
                  ),
                )
              : const BoxDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(64, 0, 40, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'arrow_popup',
                        style: text.titleSmall!.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: text.headlineMedium!.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        subtitle,
                        style: text.bodyLarge!.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 72),
                child: Phone(screen: screen, glow: glow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The square thumbnail pub.dev shows in search results: just a phone on
/// the brand color, since a caption would be unreadable that small.
class Cover extends StatelessWidget {
  const Cover({super.key, required this.screen});

  final Widget screen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      child: DecoratedBox(
        // Light pooling behind the phone, and a cool tint in one corner.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.1),
            radius: 0.8,
            colors: [
              Colors.white.withValues(alpha: 0.28),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1.0, 1.1),
              radius: 0.9,
              colors: [
                scheme.tertiary.withValues(alpha: 0.35),
                scheme.tertiary.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 50,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Phone(screen: screen),
            ),
          ),
        ),
      ),
    );
  }
}

/// A phone-sized frame around [screen].
class Phone extends StatelessWidget {
  const Phone({super.key, required this.screen, this.glow = false});

  final Widget screen;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 300,
      height: 416,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: dark ? 0.28 : 0.22),
                  blurRadius: 60,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.5 : 0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ]
            : null,
      ),
      // Over the screen, so the content doesn't cover the outline at the
      // rounded corners.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: glow
              ? scheme.primary.withValues(alpha: dark ? 0.35 : 0.30)
              : scheme.outlineVariant,
        ),
      ),
      // A safe area, as on a phone with rounded corners, keeps popups clear
      // of them. The screens themselves ignore it.
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(padding: const EdgeInsets.all(12)),
        // Its own navigator, so popups stay inside the screen as they would
        // on a phone.
        child: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => Material(color: scheme.surface, child: screen),
          ),
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header(this.title, {super.key, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: text.titleLarge!.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (icon != null) IconButton(icon: Icon(icon), onPressed: () {}),
        ],
      ),
    );
  }
}
