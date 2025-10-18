import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../common/utils/widgets.dart';
import '../../document/attribute.dart';
import '../../l10n/extensions/localizations_ext.dart';
import '../base_button/base_value_button.dart';
import '../simple_toolbar.dart';

class QuillToolbarCalloutButton extends QuillToolbarBaseButton<
    QuillToolbarCalloutButtonOptions, QuillToolbarCalloutButtonExtraOptions> {
  QuillToolbarCalloutButton({
    required super.controller,
    super.options = const QuillToolbarCalloutButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  })  : assert(options.items?.isNotEmpty ?? true),
        assert(
          options.initialValue == null || options.initialValue!.isNotEmpty,
        );

  @override
  QuillToolbarCalloutButtonState createState() =>
      QuillToolbarCalloutButtonState();
}

class QuillToolbarCalloutButtonState extends QuillToolbarBaseButtonState<
    QuillToolbarCalloutButton,
    QuillToolbarCalloutButtonOptions,
    QuillToolbarCalloutButtonExtraOptions,
    String> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeEditingValue);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  double get keyboardInsetBottom {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return MediaQueryData.fromView(view).viewInsets.bottom + kToolbarHeight;
  }

  double get maxHeightMenu {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final mq = MediaQueryData.fromView(view);
    return mq.size.height -
        mq.viewInsets.bottom -
        mq.viewPadding.bottom -
        mq.viewPadding.top -
        kToolbarHeight;
  }

  @override
  void didChangeMetrics() {
    _entry?.markNeedsBuild();
  }

  @override
  String get currentStateValue {
    final attribute =
        controller.getSelectionStyle().attributes[options.attribute.key];
    return attribute == null
        ? _defaultDisplayText
        : (_getCurrentCallout(attribute.value)?.label ?? _defaultDisplayText);
  }

  void _didChangeEditingValue() {
    setState(() {
      String? currentCallout =
          _getIsCallout(widget.controller.getSelectionStyle().attributes);
      Color? currentColor = currentCallout != null
          ? _getCurrentCallout(currentCallout)?.accent
          : null;
      if (currentColor != _currentColor) {
        setState(() {
          _currentColor = currentColor;
        });
      }
    });
  }

  String? _getIsCallout(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.callout.key)
        ? attrs[Attribute.callout.key]?.value
        : null;
  }

  String get _defaultDisplayText {
    return options.initialValue ??
        widget.options.defaultDisplayText ??
        'Callout';
  }

  List<CalloutItem> get _items {
    final items = options.items ??
        [CalloutItem(value: 'clear', label: context.loc.clear)];
    return items;
  }

  final _popoverKey = GlobalKey<AnimatedPopoverState>();
  final GlobalKey _btnKey = GlobalKey();
  OverlayEntry? _entry;

  Color? _currentColor;

  CalloutItem? _getCurrentCallout(String value) {
    return _items.firstWhereOrNull((el) => el.value == value);
  }

  @override
  String get defaultTooltip => 'Callout';

  @override
  IconData get defaultIconData => Icons.crop_square_outlined;

  void _onPressed() {
    _toggleMenu();
    afterButtonPressed?.call();
  }

  void _toggleMenu() {
    if (_entry != null) {
      _dismissOverlayMenu();
    } else {
      _showOverlayMenu();
    }
  }

  Future<void> _dismissOverlayMenu() async {
    await _popoverKey.currentState?.reverse();
    _entry!.remove();
    _entry = null;
  }

  void _showOverlayMenu() {
    final ctx = _btnKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;

    // métriques root (clavier + safe areas fiables)
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final mq = MediaQueryData.fromView(view);
    final screenW = mq.size.width;

    // bouton
    final btnSize = box.size;
    final btnTopLeft = box.localToGlobal(Offset.zero);
    final buttonTop = btnTopLeft.dy;
    final buttonLeft = btnTopLeft.dx;
    final buttonRight = buttonLeft + btnSize.width;
    final buttonCenterX = buttonLeft + btnSize.width / 2;

    // params
    const gap = 0;
    const margin = 8.0;
    const maxMenuWidth = 280.0;

    // alignement adaptatif G/D
    final alignLeft = buttonCenterX < (screenW / 2);

    _entry = OverlayEntry(
      builder: (overlayCtx) {
        // relire métriques à chaque build (rotation, clavier…)
        final v = WidgetsBinding.instance.platformDispatcher.views.first;
        final liveMQ = MediaQueryData.fromView(v);
        final screenWLive = liveMQ.size.width;
        final screenHLive = liveMQ.size.height;
        final topSafeLive = liveMQ.viewPadding.top;

        final availableAboveLive =
            (buttonTop - topSafeLive - gap).clamp(0.0, double.infinity);
        final targetWidthLive =
            math.min(maxMenuWidth, screenWLive - margin * 2);
        final bottomLive = screenHLive - (buttonTop - gap);

        // re-clamp G/D
        double? leftLive, rightLive;
        if (alignLeft) {
          leftLive =
              buttonLeft.clamp(margin, screenWLive - margin - targetWidthLive);
        } else {
          rightLive = (screenWLive - buttonRight)
              .clamp(margin, screenWLive - margin - targetWidthLive);
        }
        final itemStyle =
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
        return Stack(
          children: [
            // backdrop pour fermer (ne capte pas le focus)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissOverlayMenu,
                onVerticalDragStart: (details) {
                  _dismissOverlayMenu();
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: leftLive,
              right: rightLive,
              bottom: bottomLive,
              child: AnimatedPopover(
                key: _popoverKey,
                maxWidth: targetWidthLive,
                maxHeight: availableAboveLive,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in _items)
                      ListTile(
                        dense: true,
                        leading: item.icon != null
                            ? Icon(item.icon, color: item.accent, size: 20)
                            : null,
                        title: Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                          style: item.value == null
                              ? itemStyle.copyWith(
                                  color: options.defaultItemColor)
                              : itemStyle.copyWith(color: item.accent),
                        ),
                        onTap: () {
                          controller.formatSelection(
                            Attribute.fromKeyValue(
                              Attribute.callout.key,
                              item.value,
                            ),
                          );
                          options.onSelected?.call(item.value);
                          _toggleMenu();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    final childBuilder = this.childBuilder;
    if (childBuilder != null) {
      return childBuilder(
        options,
        QuillToolbarCalloutButtonExtraOptions(
          currentValue: currentValue,
          defaultDisplayText: _defaultDisplayText,
          controller: controller,
          context: context,
          onPressed: _onPressed,
        ),
      );
    }

    return UtilityWidgets.maybeWidget(
      enabled: tooltip.isNotEmpty || options.overrideTooltipByCallout,
      wrapper: (child) {
        var effectiveTooltip = tooltip;
        if (options.overrideTooltipByCallout) {
          effectiveTooltip = effectiveTooltip.isNotEmpty
              ? '$effectiveTooltip: $currentValue'
              : '${widget.options.defaultDisplayText ?? 'Callout'}: $currentValue';
        }
        return Tooltip(message: effectiveTooltip, child: child);
      },
      child: QuillToolbarIconButton(
        key: _btnKey,
        isSelected: false,
        iconTheme: iconTheme,
        onPressed: _onPressed,
        icon: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final hasFinalWidth = options.width != null;
    return Padding(
      padding: options.padding ?? const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Row(
        mainAxisSize: !hasFinalWidth ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          UtilityWidgets.maybeWidget(
            enabled: hasFinalWidth,
            wrapper: (child) => Expanded(child: child),
            child: Text(
              currentValue,
              maxLines: 1,
              overflow: options.labelOverflow,
              style: options.style ??
                  TextStyle(fontSize: iconSize / 1.15, color: _currentColor),
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            size: iconSize * iconButtonFactor,
            color: _currentColor,
          )
        ],
      ),
    );
  }
}
