import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/material.dart";

///
/// This allows the keyboard to be personalized by changing icons shown.
/// If a [CategoryIcon] is set as null or not defined during initialization,
/// the default icons will be used instead
class CategoryIcons {
  /// Constructor
  const CategoryIcons({
    this.recentIcon = Icons.access_time,
    this.smileyIcon = Icons.tag_faces,
    this.animalIcon = Icons.pets,
    this.foodIcon = Icons.fastfood,
    this.activityIcon = Icons.directions_run,
    this.travelIcon = Icons.location_city,
    this.objectIcon = Icons.lightbulb_outline,
    this.symbolIcon = Icons.emoji_symbols,
    this.flagIcon = Icons.flag,
  });

  final IconData recentIcon;

  final IconData smileyIcon;

  final IconData animalIcon;

  final IconData foodIcon;

  final IconData activityIcon;

  final IconData travelIcon;

  final IconData objectIcon;

  final IconData symbolIcon;

  final IconData flagIcon;
}
