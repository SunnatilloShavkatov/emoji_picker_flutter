import "package:flutter/material.dart";

@immutable
class CategoryIcon {
  /// Icon of Category
  const CategoryIcon({
    required this.icon,
    this.color = const Color.fromRGBO(211, 211, 211, 1),
    this.selectedColor = const Color.fromRGBO(178, 178, 178, 1),
  });

  /// The icon to represent the category
  final IconData icon;

  /// The default color of the icon
  final Color color;

  /// The color of the icon once the category is selected
  final Color selectedColor;

  @override
  bool operator ==(Object other) =>
      (other is CategoryIcon) &&
      other.icon == icon &&
      other.color == color &&
      other.selectedColor == selectedColor;

  @override
  int get hashCode => icon.hashCode ^ color.hashCode ^ selectedColor.hashCode;
}
