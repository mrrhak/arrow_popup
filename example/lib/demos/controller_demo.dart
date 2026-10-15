// Controller: `ArrowPopupController` opens and closes a popup from code.
//
// Use it to open a popup from somewhere other than its anchor, such as this
// tour. (To open one from the button it points at, `ArrowPopup.builder`
// needs no controller.) `show()` completes when the popup starts closing,
// so a feature tour is just a loop. The controller is a `ChangeNotifier`,
// so `isOpen` can drive the UI.

import 'dart:async';

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/material.dart';

class ControllerDemo extends StatefulWidget {
  const ControllerDemo({super.key});

  @override
  State<ControllerDemo> createState() => _ControllerDemoState();
}

typedef _TourStep = ({IconData icon, String title, String body});

class _ControllerDemoState extends State<ControllerDemo> {
  // ArrowPopup's default transitionDuration.
  static const _transition = Duration(milliseconds: 150);
  static const _dimColor = Color(0x66000000);

  static const List<_TourStep> _steps = [
    (
      icon: Icons.search_rounded,
      title: 'Search everything',
      body: 'Find messages, people and files in one place.',
    ),
    (
      icon: Icons.star_border_rounded,
      title: 'Star what matters',
      body: 'Starred messages stay pinned at the top of your inbox.',
    ),
    (
      icon: Icons.ios_share_rounded,
      title: 'Share in a tap',
      body: 'Send a conversation to anyone, even outside the app.',
    ),
  ];

  final _controllers = [for (final _ in _steps) ArrowPopupController()];

  // The tour step showing, or null when the tour isn't running.
  int? _step;
  bool _advance = false;
  bool _finished = false;

  // One dim for the whole tour, pushed under the popups, so it stays steady
  // between steps instead of each popup fading its own out and in.
  Route<void>? _backdrop;
  NavigatorState? _navigator;

  @override
  void dispose() {
    // The navigator can't change while the tree is torn down.
    final backdrop = _backdrop;
    if (backdrop != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _removeBackdrop(backdrop),
      );
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _removeBackdrop(Route<void> backdrop) {
    if (!backdrop.isActive) return;
    if (backdrop.isCurrent) {
      _navigator!.pop();
    } else {
      _navigator!.removeRoute(backdrop);
    }
  }

  // show() completes when the popup starts closing, so the tour is a plain
  // loop.
  Future<void> _startTour() async {
    setState(() => _finished = false);
    final backdrop = _backdrop = RawDialogRoute<void>(
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      barrierColor: _dimColor,
      barrierDismissible: false,
      transitionDuration: _transition,
    );
    _navigator = Navigator.of(context);
    unawaited(_navigator!.push(backdrop));
    for (var i = 0; i < _steps.length; i++) {
      setState(() => _step = i);
      _advance = false;
      // Open after the rebuild, so the popup starts with this step's content.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      await _controllers[i].show();
      if (!mounted) return;
      if (!_advance) break;
      // show() completes as the popup starts closing. Let it finish, so it
      // doesn't shrink away while the next one grows in.
      await Future<void>.delayed(_transition);
      if (!mounted) return;
    }
    setState(() {
      _finished = _advance;
      _step = null;
    });
    _removeBackdrop(backdrop);
    _backdrop = null;
  }

  void _next(int index) {
    _advance = true;
    _controllers[index].hide();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final step = _step;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A mock app bar whose actions the tour points at.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary,
                child: Icon(
                  Icons.mail_rounded,
                  size: 18,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Inbox', style: textTheme.titleMedium)),
              for (final (i, item) in _steps.indexed)
                // The tour opens these too, so each has a controller, and
                // the button opens it with the same controller.
                ArrowPopup(
                  controller: _controllers[i],
                  trigger: ArrowPopupTrigger.none,
                  // The tour dims the screen itself; a single hint dims here.
                  // Read when the popup opens.
                  barrierColor: step == null ? _dimColor : Colors.transparent,
                  style: ArrowPopupStyle(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: 14,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    maxWidth: 260,
                    shadows: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  content: _TourCard(
                    step: item,
                    index: i,
                    total: _steps.length,
                    inTour: step == i,
                    onNext: () => _next(i),
                    onClose: _controllers[i].hide,
                  ),
                  child: ListenableBuilder(
                    listenable: _controllers[i],
                    builder: (context, _) => IconButton(
                      isSelected: _controllers[i].isOpen,
                      icon: Icon(item.icon),
                      onPressed: step == null
                          ? () => _controllers[i].show()
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.icon(
              onPressed: step == null ? _startTour : null,
              icon: Icon(
                _finished ? Icons.replay_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(_finished ? 'Replay tour' : 'Start tour'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step != null
                        ? 'Step ${step + 1} of ${_steps.length}'
                        : _finished
                        ? 'Tour finished'
                        : 'Or tap any icon for its hint',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: step != null
                          ? (step + 1) / _steps.length
                          : _finished
                          ? 1
                          : 0,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.step,
    required this.index,
    required this.total,
    required this.inTour,
    required this.onNext,
    required this.onClose,
  });

  final _TourStep step;
  final int index;
  final int total;
  final bool inTour;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onColor = colorScheme.onSurface;
    final accent = colorScheme.primary;
    final last = index == total - 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(step.icon, color: accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                step.title,
                style: textTheme.titleSmall?.copyWith(color: onColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          step.body,
          style: textTheme.bodyMedium?.copyWith(
            color: onColor.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (inTour)
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 4),
                  width: i == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == index ? accent : onColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            const Spacer(),
            if (inTour && !last)
              TextButton(
                onPressed: onClose,
                style: TextButton.styleFrom(
                  foregroundColor: onColor.withValues(alpha: 0.7),
                ),
                child: const Text('Skip'),
              ),
            TextButton(
              onPressed: inTour ? onNext : onClose,
              style: TextButton.styleFrom(foregroundColor: accent),
              child: Text(!inTour ? 'Got it' : (last ? 'Done' : 'Next')),
            ),
          ],
        ),
      ],
    );
  }
}
