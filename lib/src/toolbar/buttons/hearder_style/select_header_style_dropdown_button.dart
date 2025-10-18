import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../document/attribute.dart';
import '../../../l10n/extensions/localizations_ext.dart';
import '../../base_button/base_value_button.dart';

import '../../config/simple_toolbar_config.dart';
import '../quill_icon_button.dart';

typedef QuillToolbarSelectHeaderStyleDropdownBaseButton
    = QuillToolbarBaseButton<QuillToolbarSelectHeaderStyleDropdownButtonOptions,
        QuillToolbarSelectHeaderStyleDropdownButtonExtraOptions>;

typedef QuillToolbarSelectHeaderStyleDropdownBaseButtonsState<
        W extends QuillToolbarSelectHeaderStyleDropdownButton>
    = QuillToolbarCommonButtonState<
        W,
        QuillToolbarSelectHeaderStyleDropdownButtonOptions,
        QuillToolbarSelectHeaderStyleDropdownButtonExtraOptions>;

class QuillToolbarSelectHeaderStyleDropdownButton
    extends QuillToolbarSelectHeaderStyleDropdownBaseButton {
  const QuillToolbarSelectHeaderStyleDropdownButton({
    required super.controller,
    super.options = const QuillToolbarSelectHeaderStyleDropdownButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  });

  @override
  QuillToolbarSelectHeaderStyleDropdownBaseButtonsState createState() =>
      _QuillToolbarSelectHeaderStyleDropdownButtonState();
}

class _QuillToolbarSelectHeaderStyleDropdownButtonState
    extends QuillToolbarSelectHeaderStyleDropdownBaseButtonsState
    with WidgetsBindingObserver {
  @override
  String get defaultTooltip => context.loc.headerStyle;

  @override
  IconData get defaultIconData => Icons.question_mark_outlined;

  Attribute<dynamic> _selectedItem = Attribute.header;

  final _popoverKey = GlobalKey<AnimatedPopoverState>();
  final GlobalKey _btnKey = GlobalKey();
  OverlayEntry? _entry;


  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeEditingValue);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    WidgetsBinding.instance.removeObserver(this);
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
  void didUpdateWidget(
      covariant QuillToolbarSelectHeaderStyleDropdownButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    widget.controller
      ..removeListener(_didChangeEditingValue)
      ..addListener(_didChangeEditingValue);
  }

  void _didChangeEditingValue() {
    final newSelectedItem = _getHeaderValue();
    if (newSelectedItem == _selectedItem) {
      return;
    }
    setState(() {
      _selectedItem = newSelectedItem;
    });
  }

  Attribute<dynamic> _getHeaderValue() {
    final attr = widget.controller.toolbarButtonToggler[Attribute.header.key];
    if (attr != null) {
      // checkbox tapping causes controller.selection to go to offset 0
      widget.controller.toolbarButtonToggler.remove(Attribute.header.key);
      return attr;
    }
    return widget.controller
            .getSelectionStyle()
            .attributes[Attribute.header.key] ??
        Attribute.header;
  }

  TextStyle? _getHeaderAttributeStyle(Attribute<int?> attribute){
      return widget.options.attributes?[attribute];
  }

  String _label(Attribute<dynamic> value) {
    final label = switch (value) {
      Attribute.h1 => context.loc.heading1,
      Attribute.h2 => context.loc.heading2,
      Attribute.h3 => context.loc.heading3,
      Attribute.h4 => context.loc.heading4,
      Attribute.h5 => context.loc.heading5,
      Attribute.h6 => context.loc.heading6,
      Attribute.header =>
        widget.options.defaultDisplayText ?? context.loc.normal,
      Attribute<dynamic>() => throw ArgumentError(),
    };
    return label;
  }

  List<Attribute<int?>> get headerAttributes {
    return widget.options.attributes!=null ? widget.options.attributes!.keys.toList() :
        [
          Attribute.h1,
          Attribute.h2,
          Attribute.h3,
          Attribute.header,
        ];
  }

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
                  children: headerAttributes
                      .map(
                        (e) => ListTile(
                          dense: true,
                          title:
                              Text(_label(e), overflow: TextOverflow.ellipsis, style:_getHeaderAttributeStyle(e) ?? Theme.of(context).textTheme.bodyLarge),
                          onTap: () {
                            setState(() => _selectedItem = e);
                            widget.controller.formatSelection(_selectedItem);
                            _toggleMenu();
                          },
                        ),
                      )
                      .toList(),
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
        widget.options,
        QuillToolbarSelectHeaderStyleDropdownButtonExtraOptions(
          currentValue: _selectedItem,
          context: context,
          controller: widget.controller,
          onPressed: () {
            throw UnimplementedError('Not implemented yet.');
          },
        ),
      );
    }

    final isMaterial3 = Theme.of(context).useMaterial3;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _label(_selectedItem),
          style: widget.options.textStyle ??
              TextStyle(
                fontSize: iconSize / 1.15,
              ),
        ),
        Icon(
          Icons.arrow_drop_down,
          size: iconSize * iconButtonFactor,
        ),
      ],
    );
    if (!isMaterial3) {
      return RawMaterialButton(
        onPressed: _onPressed,
        child: child,
      );
    }
    return QuillToolbarIconButton(
      key: _btnKey,
      onPressed: _onPressed,
      icon: child,
      isSelected: false,
      iconTheme: iconTheme,
      tooltip: tooltip,
    );
  }
}
