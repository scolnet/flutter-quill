import 'package:flutter/material.dart';

class AnimatedPopover extends StatefulWidget {
  const AnimatedPopover({
    required this.child,
    required this.maxWidth,
    required this.maxHeight,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final double maxHeight;

  @override
  State<AnimatedPopover> createState() => AnimatedPopoverState();
}

class AnimatedPopoverState extends State<AnimatedPopover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  final _sc = ScrollController();
  bool _showTop = false;
  bool _showBottom = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 140),
    );
    final curve = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(curve);
    _slide =
        Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(curve);
    _ctrl.forward();

    _sc.addListener(_updateIndicators);
    // premier calcul après layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicators());
  }

  Future<void> reverse() async {
    if (mounted) await _ctrl.reverse();
  }

  @override
  void dispose() {
    _sc
      ..removeListener(_updateIndicators)
      ..dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _updateIndicators() {
    if (!_sc.hasClients) return;
    final atTop = _sc.position.pixels <= _sc.position.minScrollExtent + 0.5;
    final atBottom = _sc.position.pixels >= _sc.position.maxScrollExtent - 0.5;
    final showTop = !atTop;
    final showBottom = !atBottom;
    if (showTop != _showTop || showBottom != _showBottom) {
      if (mounted) {
        setState(() {
          _showTop = showTop;
          _showBottom = showBottom;
        });
      }
    }
  }

  void _pageUp() {
    if (!_sc.hasClients) return;
    final delta = widget.maxHeight * 0.6; // “page” ~ 60%
    _sc.animateTo(
      (_sc.position.pixels - delta)
          .clamp(_sc.position.minScrollExtent, _sc.position.maxScrollExtent),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
    );
  }

  void _pageDown() {
    if (!_sc.hasClients) return;
    final delta = widget.maxHeight * 0.6;
    _sc.animateTo(
      (_sc.position.pixels + delta)
          .clamp(_sc.position.minScrollExtent, _sc.position.maxScrollExtent),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: false,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1),
            ),
            elevation: 5,
            clipBehavior: Clip.antiAlias,
            color: colorScheme.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.maxWidth,
                maxHeight: widget.maxHeight,
              ),
              child: IntrinsicWidth(
                child: Stack(
                  children: [
                    // LISTE SCROLLABLE
                    SingleChildScrollView(
                      controller: _sc,
                      child: widget.child,
                    ),

                    // FADE + CHEVRON TOP
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: IgnorePointer(
                        ignoring: !_showTop,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: _showTop ? 1 : 0,
                          child: _EdgeHint(
                            alignment: Alignment.topCenter,
                            onTap: _pageUp,
                            icon: Icons.expand_less,
                          ),
                        ),
                      ),
                    ),

                    // FADE + CHEVRON BOTTOM
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        ignoring: !_showBottom,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: _showBottom ? 1 : 0,
                          child: _EdgeHint(
                            alignment: Alignment.bottomCenter,
                            onTap: _pageDown,
                            icon: Icons.expand_more,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EdgeHint extends StatelessWidget {
  const _EdgeHint({
    required this.alignment,
    required this.onTap,
    required this.icon,
  });

  final Alignment alignment;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // Dégradé léger pour suggérer du contenu caché
    final Color gradientColor = Theme.of(context).brightness==Brightness.dark?Colors.white10 : Colors.black12;
    final gradient = alignment == Alignment.topCenter
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientColor, Colors.transparent],
          )
        : LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [gradientColor, Colors.transparent],
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: SizedBox(
          height: 22,
          width: double.infinity,
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
