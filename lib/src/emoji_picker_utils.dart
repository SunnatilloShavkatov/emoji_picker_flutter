import "dart:math";

import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:emoji_picker_flutter/src/emoji_picker_internal_utils.dart";
import "package:flutter/material.dart";

/// Emoji Regex
/// Keycap Sequence '((\u0023|\u002a|[\u0030-\u0039])\ufe0f\u20e3){1}'
/// Issue: https://github.com/flutter/flutter/issues/36062
const String emojiRegex =
    r"((\u0023|\u002a|[\u0030-\u0039])\ufe0f\u20e3){1}|\p{Emoji}|\u200D|\uFE0F";

/// Helper class that provides extended usage
class EmojiPickerUtils {
  /// Singleton Constructor
  factory EmojiPickerUtils() => _singleton;

  EmojiPickerUtils._internal();

  static final EmojiPickerUtils _singleton = EmojiPickerUtils._internal();
  final List<Emoji> _allAvailableEmojiEntities = <Emoji>[];
  RegExp? _emojiRegExp;

  /// Returns list of recently used emoji from cache
  Future<List<RecentEmoji>> getRecentEmojis() async =>
      (await EmojiPickerInternalUtils.getInstance()).getRecentEmojis();

  /// Search for related emoticons based on keywords
  Future<List<Emoji>> searchEmoji(
    String keyword,
    List<CategoryEmoji> emojiSet, {
    bool checkPlatformCompatibility = true,
  }) async {
    if (keyword.isEmpty) {
      return <Emoji>[];
    }

    if (_allAvailableEmojiEntities.isEmpty) {
      final EmojiPickerInternalUtils emojiPickerInternalUtils =
          await EmojiPickerInternalUtils.getInstance();

      final List<CategoryEmoji> data = <CategoryEmoji>[...emojiSet]
        ..removeWhere((CategoryEmoji e) => e.category == Category.recent);
      final List<CategoryEmoji> availableCategoryEmoji =
          checkPlatformCompatibility
              ? await emojiPickerInternalUtils.filterUnsupported(data)
              : data;

      // Set all the emoji entities
      for (final CategoryEmoji emojis in availableCategoryEmoji) {
        _allAvailableEmojiEntities.addAll(emojis.emoji);
      }
    }

    return _allAvailableEmojiEntities
        .toSet()
        .where(
          (Emoji emoji) =>
              emoji.name.toLowerCase().contains(keyword.toLowerCase()),
        )
        .toSet()
        .toList();
  }

  /// Add an emoji to recently used list or increase its counter
  Future<void> addEmojiToRecentlyUsed({
    required GlobalKey<EmojiPickerState> key,
    required Emoji emoji,
    Config config = const Config(),
  }) async =>
      (await EmojiPickerInternalUtils.getInstance())
          .addEmojiToRecentlyUsed(emoji: emoji, config: config)
          .then(
            (List<RecentEmoji> recentEmojiList) =>
                key.currentState?.updateRecentEmoji(recentEmojiList),
          );

  /// Produce a list of spans to adjust style for emoji characters.
  /// Spans enclosing emojis will have [parentStyle] combined with [emojiStyle].
  /// Other spans will not have an explicit style (this method does not set
  /// [parentStyle] to the whole text.
  List<InlineSpan> setEmojiTextStyle(
    String text, {
    required TextStyle emojiStyle,
    TextStyle? parentStyle,
  }) {
    final TextStyle composedEmojiStyle = (parentStyle ?? const TextStyle())
        .merge(defaultEmojiTextStyle)
        .merge(emojiStyle);

    final List<TextSpan> spans = <TextSpan>[];
    final List<RegExpMatch> matches = getEmojiRegex().allMatches(text).toList();
    int cursor = 0;
    for (final RegExpMatch match in matches) {
      if (cursor != match.start) {
        // Non emoji text + following emoji
        spans
          ..add(
            TextSpan(
              text: text.substring(cursor, match.start),
              style: parentStyle,
            ),
          )
          ..add(
            TextSpan(
              text: text.substring(match.start, match.end),
              style: composedEmojiStyle,
            ),
          );
      } else {
        if (spans.isEmpty) {
          // Create new span if no previous emoji TextSpan exists
          spans.add(
            TextSpan(
              text: text.substring(match.start, match.end),
              style: composedEmojiStyle,
            ),
          );
        } else {
          // Update last span if current text is still emoji
          final int lastIndex = spans.length - 1;
          final String lastText = spans[lastIndex].text ?? "";
          final String currentText = text.substring(match.start, match.end);
          spans[lastIndex] = TextSpan(
            text: "$lastText$currentText",
            style: composedEmojiStyle,
          );
        }
      }
      // Update cursor
      cursor = match.end;
    }
    // Add remaining text
    if (cursor != text.length) {
      spans.add(
        TextSpan(
          text: text.substring(cursor, text.length),
          style: parentStyle,
        ),
      );
    }
    return spans;
  }

  /// Applies skin tone to given emoji
  Emoji applySkinTone(Emoji emoji, String color) {
    final List<int> codeUnits = emoji.emoji.codeUnits;
    final List<int> result = List<int>.empty(growable: true)
      // Basic emoji without gender (until char 2)
      ..addAll(codeUnits.sublist(0, min(codeUnits.length, 2)))
      // Skin tone
      ..addAll(color.codeUnits);
    // add the rest of the emoji (gender, etc.) again
    if (codeUnits.length >= 2) {
      result.addAll(codeUnits.sublist(2));
    }
    return emoji.copyWith(emoji: String.fromCharCodes(result));
  }

  /// Clears the list of recent emojis
  Future<void> clearRecentEmojis({
    required GlobalKey<EmojiPickerState> key,
  }) async =>
      (await EmojiPickerInternalUtils.getInstance())
          .clearRecentEmojisInLocalStorage()
          .then(
            (_) => key.currentState
                ?.updateRecentEmoji(<RecentEmoji>[], refresh: true),
          );

  /// Returns the emoji regex
  /// Based on https://unicode.org/reports/tr51/
  RegExp getEmojiRegex() => _emojiRegExp ?? RegExp(emojiRegex, unicode: true);
}
