// Triggers: `trigger` picks the gesture on the child that opens the popup.
//
// `tap` shows who an avatar is, `longPress` opens a reaction bar on
// chat messages, `doubleTap` likes a photo, and `hover` shows a tool's
// shortcut like a tooltip. The child must not handle the same gesture
// itself, so these use plain widgets, not buttons.

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class TriggerDemo extends StatelessWidget {
  const TriggerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TriggerCard(
          icon: Icons.touch_app_outlined,
          gesture: 'Tap',
          hint: 'an avatar to see who it is',
          child: _TeamDemo(),
        ),
        SizedBox(height: 12),
        _TriggerCard(
          icon: Icons.back_hand_outlined,
          gesture: 'Long press',
          hint: 'any message to react',
          child: _ReactionDemo(),
        ),
        SizedBox(height: 12),
        _TriggerCard(
          icon: Icons.ads_click_rounded,
          gesture: 'Double tap',
          hint: 'the photo to like it',
          child: _LikeDemo(),
        ),
        SizedBox(height: 12),
        _TriggerCard(
          icon: Icons.mouse_outlined,
          gesture: 'Hover',
          hint: 'a tool for a moment, or tap it, to see its shortcut',
          child: _ShortcutDemo(),
        ),
      ],
    );
  }
}

class _TriggerCard extends StatelessWidget {
  const _TriggerCard({
    required this.icon,
    required this.gesture,
    required this.hint,
    required this.child,
  });

  final IconData icon;
  final String gesture;
  final String hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      gesture,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(hint, style: textTheme.bodySmall)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

enum _Status {
  online('Online', Color(0xFF22C55E)),
  away('Away', Color(0xFFF59E0B)),
  offline('Offline', Color(0xFF9CA3AF));

  const _Status(this.label, this.color);

  final String label;
  final Color color;
}

typedef _Member = ({
  String name,
  String handle,
  String role,
  _Status status,
  List<(IconData, String)> info,
});

/// Tap: an avatar that shows who it is.
class _TeamDemo extends StatelessWidget {
  const _TeamDemo();

  static const List<_Member> _team = [
    (
      name: 'Mrr Hak',
      handle: 'mrrhak',
      role: 'Package author',
      status: _Status.online,
      info: [
        (Icons.language_rounded, 'mrrhak.com'),
        (Icons.code_rounded, 'github.com/mrrhak'),
      ],
    ),
    (
      name: 'David Ara',
      handle: 'david.ara',
      role: 'User',
      status: _Status.online,
      info: [
        (Icons.location_on_outlined, 'Singapore'),
        (Icons.calendar_today_outlined, 'Joined March 2025'),
      ],
    ),
    (
      name: 'Mina',
      handle: 'mina.k',
      role: 'User',
      status: _Status.away,
      info: [
        (Icons.location_on_outlined, 'Seoul'),
        (Icons.calendar_today_outlined, 'Joined July 2025'),
      ],
    ),
    (
      name: 'Leo',
      handle: 'leo_dev',
      role: 'User',
      status: _Status.offline,
      info: [
        (Icons.location_on_outlined, 'Berlin'),
        (Icons.calendar_today_outlined, 'Joined January 2026'),
      ],
    ),
    (
      name: 'Ana',
      handle: 'ana.s',
      role: 'User',
      status: _Status.online,
      info: [
        (Icons.location_on_outlined, 'Lisbon'),
        (Icons.calendar_today_outlined, 'Joined May 2026'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final member in _team)
          ArrowPopup(
            key: ValueKey('member-${member.name}'),
            style: ArrowPopupStyle(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: 14,
              padding: const EdgeInsets.all(14),
              maxWidth: 260,
              shadows: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // Round, like the avatar, when it has keyboard focus.
            focusDecoration: ShapeDecoration(
              shape: CircleBorder(
                side: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
            ),
            content: _MemberCard(member: member),
            // A plain avatar, so ArrowPopup gets the tap.
            child: _MemberAvatar(member: member, radius: 24),
          ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.radius});

  final _Member member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dot = radius * 0.58;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: colorScheme.secondaryContainer,
          // Initials, so "Mrr Hak" shows MH.
          child: Text(
            member.name.split(' ').map((word) => word[0]).take(2).join(),
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontSize: radius * 0.66,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: member.status.color,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final _Member member;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MemberAvatar(member: member, radius: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: textTheme.titleSmall),
                  Text(
                    '@${member.handle}',
                    style: textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Pill(
              color: colorScheme.secondaryContainer,
              child: Text(
                member.role,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            _Pill(
              color: colorScheme.surfaceContainerLow,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: member.status.color),
                  const SizedBox(width: 5),
                  Text(member.status.label, style: textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final (icon, text) in member.info)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: muted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    style: textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}

/// Long press: chat messages that open a reaction bar.
class _ReactionDemo extends StatelessWidget {
  const _ReactionDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChatBubble(text: 'Shipped the new popup package today 🚀'),
        SizedBox(height: 8),
        _ChatBubble(text: 'Nice! Does it work on long press?', sent: true),
        SizedBox(height: 8),
        _ChatBubble(text: 'Try it: long press any message 👆'),
      ],
    );
  }
}

/// One message. Received ones sit on the left, sent ones on the right.
class _ChatBubble extends StatefulWidget {
  const _ChatBubble({required this.text, this.sent = false});

  final String text;
  final bool sent;

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  static const _reactions = ['👍', '❤️', '😂', '😮', '😢', '🎉'];

  final _controller = ArrowPopupController();
  String? _reaction;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _react(String reaction) {
    setState(() => _reaction = _reaction == reaction ? null : reaction);
    _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sent = widget.sent;
    final reaction = _reaction;
    const round = Radius.circular(18);
    const tail = Radius.circular(4);
    return Align(
      alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ArrowPopup(
            controller: _controller,
            trigger: ArrowPopupTrigger.longPress,
            placement: ArrowPopupPlacement.above,
            style: ArrowPopupStyle(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: 999,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              shadows: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final emoji in _reactions)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _react(emoji),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: emoji == reaction
                            ? colorScheme.primaryContainer
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              margin: EdgeInsets.only(bottom: reaction == null ? 0 : 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: sent
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                // The small corner points at the sender's side.
                borderRadius: BorderRadius.only(
                  topLeft: round,
                  topRight: round,
                  bottomLeft: sent ? round : tail,
                  bottomRight: sent ? tail : round,
                ),
              ),
              child: Text(
                widget.text,
                style: TextStyle(
                  color: sent ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (reaction != null)
            Positioned(
              left: sent ? 8 : null,
              right: sent ? null : 8,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(reaction, style: const TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Double tap: a photo that is liked with a heart.
class _LikeDemo extends StatefulWidget {
  const _LikeDemo();

  @override
  State<_LikeDemo> createState() => _LikeDemoState();
}

class _LikeDemoState extends State<_LikeDemo> {
  bool _liked = false;
  int _likes = 41;

  void _like() {
    if (_liked) return;
    setState(() {
      _liked = true;
      _likes++;
    });
  }

  void _toggle() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // The same pink as the "Liked!" popup.
    const accent = Color(0xFFE11D48);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArrowPopup(
          trigger: ArrowPopupTrigger.doubleTap,
          barrierColor: Colors.transparent,
          // A quick confirmation that goes away by itself.
          autoCloseDuration: const Duration(milliseconds: 1200),
          onOpen: _like,
          style: const ArrowPopupStyle(
            color: Color(0xFFE11D48),
            borderRadius: 999,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shadows: [BoxShadow(color: Color(0x66E11D48), blurRadius: 16)],
          ),
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('Liked!', style: TextStyle(color: Colors.white)),
            ],
          ),
          // A quiet landscape in the theme's own tones.
          child: ClipRRect(
            key: const ValueKey('photo'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 140,
              color: colorScheme.surfaceContainerHighest,
              child: Stack(
                children: [
                  Positioned(
                    right: 28,
                    top: 22,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.25,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40,
                    bottom: -30,
                    child: Icon(
                      Icons.landscape_rounded,
                      size: 150,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.18,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -14,
                    child: Icon(
                      Icons.landscape_rounded,
                      size: 120,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: _toggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(_liked),
                  color: _liked ? accent : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text('$_likes likes', style: textTheme.labelLarge),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Weekend in the mountains',
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Hover: a formatting toolbar whose tools show their shortcut.
class _ShortcutDemo extends StatelessWidget {
  const _ShortcutDemo();

  static const _tools = [
    (Icons.format_bold_rounded, 'Bold', 'B'),
    (Icons.format_italic_rounded, 'Italic', 'I'),
    (Icons.format_underlined_rounded, 'Underline', 'U'),
    (Icons.link_rounded, 'Add link', 'K'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => true,
      _ => false,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, label, key) in _tools)
              ArrowPopup(
                key: ValueKey('tool-$label'),
                trigger: ArrowPopupTrigger.hover,
                // Like toolbar tooltips, it opens only once the mouse rests,
                // so sweeping across the tools shows nothing.
                waitDuration: const Duration(milliseconds: 800),
                // Below, like toolbar tooltips, so the card's hint stays
                // readable.
                placement: ArrowPopupPlacement.below,
                // Screen readers read this when they reach the tool, since
                // the hover popup itself isn't announced.
                semanticLabel: '$label, ${apple ? 'Command' : 'Control'} $key',
                style: ArrowPopupStyle(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: 8,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  arrowSize: const Size(12, 6),
                  gap: 4,
                  shadows: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: textTheme.labelMedium),
                    const SizedBox(width: 8),
                    Text(
                      apple ? '⌘$key' : 'Ctrl+$key',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // A plain icon, so ArrowPopup gets the hover and the tap.
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
