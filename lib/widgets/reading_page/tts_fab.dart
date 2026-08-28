import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/tts/base_tts.dart';
import 'package:anx_reader/service/tts/tts_handler.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';

class TtsFab extends StatefulWidget {
  const TtsFab({super.key});

  @override
  State<TtsFab> createState() => _TtsFabState();
}

class _TtsFabState extends State<TtsFab> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Prefs().reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _collapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TtsStateEnum>(
      valueListenable: TtsHandler().ttsStateNotifier,
      builder: (context, ttsState, _) {
        final isPlaying = ttsState == TtsStateEnum.playing;
        final ttsActive =
            ttsState == TtsStateEnum.playing || ttsState == TtsStateEnum.paused;

        // Collapse when TTS stops, but keep widget alive so State is preserved
        // during brief stopped transitions (e.g. between sentences).
        if (ttsState == TtsStateEnum.stopped) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _collapse());
        }

        return AnimatedOpacity(
          opacity: ttsActive ? 1.0 : 0.0,
          duration: Prefs().reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !ttsActive,
            child: PointerInterceptor(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Expanded action buttons (slide in from right, appear to left of main FAB)
                  AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.centerRight,
                          widthFactor: _expandAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilledContainer(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.0, vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionButton(
                                icon: EvaIcons.chevron_left,
                                onPressed: () {
                                  TtsHandler().playPrevious();
                                },
                              ),
                              _ActionButton(
                                icon: isPlaying
                                    ? EvaIcons.pause_circle_outline
                                    : EvaIcons.play_circle_outline,
                                onPressed: () {
                                  if (isPlaying) {
                                    audioHandler.pause();
                                  } else {
                                    audioHandler.play();
                                  }
                                },
                              ),
                              _ActionButton(
                                icon: EvaIcons.chevron_right,
                                onPressed: () {
                                  TtsHandler().playNext();
                                },
                              ),
                              _ActionButton(
                                icon: EvaIcons.stop_circle_outline,
                                onPressed: () {
                                  audioHandler.stop();
                                  _collapse();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Main FAB — heroTag: null disables the built-in Hero to avoid
                  // nesting inside the reading page's own Hero animation.
                  FloatingActionButton(
                    heroTag: null,
                    mini: true,
                    onPressed: _toggleExpanded,
                    elevation: 4,
                    child: AnimatedSwitcher(
                      duration: Prefs().reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      child: _isExpanded
                          ? const Icon(
                              Icons.close,
                              key: ValueKey('close'),
                              size: 20,
                            )
                          : Icon(
                              isPlaying
                                  ? EvaIcons.pause_circle_outline
                                  : EvaIcons.play_circle_outline,
                              key: ValueKey('tts_state'),
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22),
      onPressed: onPressed,
      splashRadius: 20,
      visualDensity: VisualDensity.compact,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
