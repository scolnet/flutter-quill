
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BlockHeaderSpec {
  final String? text;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final IconData? icon;
  final Color? iconColor;
  final double iconGap;

  const BlockHeaderSpec({
    this.text,
    this.textStyle,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 6),
    this.icon,
    this.iconColor,
    this.iconGap = 6.0,
  });

  bool get hasSomething => (text != null && text!.isNotEmpty) || icon != null;
}

class BlockResolvedDecoration {
  final BoxDecoration decoration;
  final EdgeInsets contentPadding;
  final BlockHeaderSpec? header;

  const BlockResolvedDecoration({
    required this.decoration,
    required this.contentPadding,
    this.header,
  });

  BlockResolvedDecoration copyWith({
    BoxDecoration? decoration,
    EdgeInsets? contentPadding,
    BlockHeaderSpec? header,
  }) {
    return BlockResolvedDecoration(
      decoration: decoration ?? this.decoration,
      contentPadding: contentPadding ?? this.contentPadding,
      header: header ?? this.header,
    );
  }
}
