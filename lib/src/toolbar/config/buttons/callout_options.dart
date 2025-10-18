import 'package:flutter/material.dart';

import '../../../document/attribute.dart';
import '../base_button_options.dart';

class CalloutItem {

  const CalloutItem({
    required this.label, 
    this.value,
    this.icon,
    this.accent,
  });
  
  final String? value;
  final String label;
  final IconData? icon;
  final Color? accent;

}


@immutable
class QuillToolbarCalloutButtonExtraOptions
    extends QuillToolbarBaseButtonExtraOptions {
  const QuillToolbarCalloutButtonExtraOptions({
    required this.defaultDisplayText,
    required this.currentValue,
    required super.controller,
    required super.context,
    required super.onPressed,
  });
  final String defaultDisplayText;
  final String currentValue;
}

class QuillToolbarCalloutButtonOptions extends QuillToolbarBaseButtonOptions<
    QuillToolbarCalloutButtonOptions,
    QuillToolbarCalloutButtonExtraOptions> {
  const QuillToolbarCalloutButtonOptions({
    this.attribute = Attribute.callout,
    this.items,
    super.iconData,
    super.afterButtonPressed,
    super.tooltip,
    super.iconTheme,
    super.childBuilder,
    this.onSelected,
    this.padding,
    this.style,
    this.width,
    this.initialValue,
    this.labelOverflow = TextOverflow.visible,
    this.overrideTooltipByCallout = false,
    this.itemHeight,
    this.itemPadding,
    this.defaultItemColor = Colors.red,
    this.renderCallout = true,
    super.iconSize,
    super.iconButtonFactor,
    this.defaultDisplayText,
  });

  /// Defaults to:
  ///
  ///
  /// ```dart
  /// {
  ///  'Sans Serif': 'sans-serif',
  ///  'Serif': 'serif',
  ///  'Monospace': 'monospace',
  ///  'Ibarra Real Nova': 'ibarra-real-nova',
  ///  'SquarePeg': 'square-peg',
  ///  'Nunito': 'nunito',
  ///  'Pacifico': 'pacifico',
  ///  'Roboto Mono': 'roboto-mono',
  ///  context.loc.clear: 'Clear'
  /// }
  /// ```
  ///
  /// See also: [QuillToolbarCalloutButtonState._items]
  final List<CalloutItem>? items;
  final ValueChanged<String?>? onSelected;
  final Attribute attribute;

  final EdgeInsetsGeometry? padding;
  final TextStyle? style;
  final double? width;
  final bool renderCallout;
  final String? initialValue;
  final TextOverflow labelOverflow;
  final bool overrideTooltipByCallout;
  final double? itemHeight;
  final EdgeInsets? itemPadding;
  final Color? defaultItemColor;
  final String? defaultDisplayText;
}
