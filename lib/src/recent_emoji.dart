// ignore_for_file: avoid_annotating_with_dynamic, avoid_dynamic_calls

import "package:emoji_picker_flutter/src/emoji.dart";

/// Class that holds an recent emoji
/// Recent Emoji has an instance of the emoji
/// And a counter, which counts how often this emoji
/// has been used before

class RecentEmoji {
  /// Constructor
  RecentEmoji(this.emoji, this.counter);

  /// Parse RecentEmoji from json
  factory RecentEmoji.fromJson(dynamic json) => RecentEmoji(
        Emoji.fromJson(json["emoji"] as Map<String, dynamic>),
        json["counter"] as int,
      );

  /// Emoji instance
  final Emoji emoji;

  /// Counter how often emoji has been used before
  int counter = 0;

  /// Encode RecentEmoji to json
  Map<String, dynamic> toJson() => <String, dynamic>{
        "emoji": emoji,
        "counter": counter,
      };
}
