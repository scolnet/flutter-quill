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
    String> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
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

  Color? _currentColor;

  CalloutItem? _getCurrentCallout(String value) {
    return _items.firstWhereOrNull((el) => el.value == value);
  }

  @override
  String get defaultTooltip => 'Callout';

  @override
  IconData get defaultIconData => Icons.crop_square_outlined;

  void _onPressed() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
    afterButtonPressed?.call();
  }

  final _menuController = MenuController();

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
      child: MenuAnchor(
        controller: _menuController,
        menuChildren: [
          for (CalloutItem item in _items)
            MenuItemButton(
              key: ValueKey(item.value),
              onPressed: () {
                final newValue = item.value;
                final keyName = item.label;
                setState(() {
                  if (newValue != null) {
                    currentValue = keyName;
                    _currentColor = item.accent;
                  } else {
                    currentValue = _defaultDisplayText;
                    _currentColor = null;
                  }

                  controller.formatSelection(
                    Attribute.fromKeyValue(
                      Attribute.callout.key,
                      newValue,
                    ),
                  );
                  options.onSelected?.call(newValue);
                });
              },
              leadingIcon: item.icon != null
                  ? Icon(item.icon, color: item.accent, size: 20)
                  : null,
              child: Text(
                item.label,
                style: TextStyle(
                  color: item.value == null
                      ? options.defaultItemColor
                      : item.accent,
                ),
              ),
            ),
        ],
        child: Builder(
          builder: (context) {
            final isMaterial3 = Theme.of(context).useMaterial3;
            if (!isMaterial3) {
              return RawMaterialButton(
                onPressed: _onPressed,
                child: _buildContent(context),
              );
            }
            return QuillToolbarIconButton(
              isSelected: false,
              iconTheme: iconTheme,
              onPressed: _onPressed,
              icon: _buildContent(context),
            );
          },
        ),
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
