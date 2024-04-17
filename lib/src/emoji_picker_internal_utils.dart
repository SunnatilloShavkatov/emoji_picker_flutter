import "dart:convert";
import "dart:io";
import "dart:math";

import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/services.dart";
import "package:hive/hive.dart";
import "package:path_provider/path_provider.dart";

/// Initial value for RecentEmoji
const int initVal = 1;

/// Helper class that provides internal usage
class EmojiPickerInternalUtils {
  EmojiPickerInternalUtils._internal();

  static EmojiPickerInternalUtils? _singleton;

  static Future<EmojiPickerInternalUtils> getInstance() async {
    if (_singleton != null) {
      return _singleton!;
    }
    _singleton ??= EmojiPickerInternalUtils._internal();
    await _initHive();
    return _singleton!;
  }

  static Future<void> init() async {
    await _initHive();
  }

  // Establish communication with native
  static const MethodChannel _platform = MethodChannel("emoji_picker_flutter");

  // Get available emoji for given category title
  Future<CategoryEmoji> _getAvailableEmojis(CategoryEmoji category) async {
    final List<bool> available = (await _platform.invokeListMethod<bool>(
      "getSupportedEmojis",
      <String, List<String>>{
        "source":
            category.emoji.map((Emoji e) => e.emoji).toList(growable: false),
      },
    ))!;

    return category.copyWith(
      emoji: <Emoji>[
        for (int i = 0; i < available.length; i++)
          if (available[i]) category.emoji[i],
      ],
    );
  }

  /// Filters out emojis not supported on the platform
  Future<List<CategoryEmoji>> filterUnsupported(
    List<CategoryEmoji> data,
  ) async {
    if (!Platform.isAndroid) {
      return data;
    }
    final List<Future<CategoryEmoji>> futures = <Future<CategoryEmoji>>[
      for (final CategoryEmoji cat in data) _getAvailableEmojis(cat),
    ];
    return Future.wait(futures);
  }

  /// Returns list of recently used emoji from cache
  Future<List<RecentEmoji>> getRecentEmojis() async {
    final String? emojiJson = _box.get("recent", defaultValue: null);
    if (emojiJson == null) {
      return <RecentEmoji>[];
    }
    final List<dynamic> json = jsonDecode(emojiJson) as List<dynamic>;
    return json.map<RecentEmoji>(RecentEmoji.fromJson).toList();
  }

  /// Add an emoji to recently used list
  Future<List<RecentEmoji>> addEmojiToRecentlyUsed({
    required Emoji emoji,
    Config config = const Config(),
  }) async {
    // Remove emoji's skin tone in Recent-Category
    if (emoji.hasSkinTone) {
      emoji = removeSkinTone(emoji);
    }
    List<RecentEmoji> recentEmoji = await getRecentEmojis();
    final int recentEmojiIndex = recentEmoji.indexWhere(
      (RecentEmoji element) => element.emoji.emoji == emoji.emoji,
    );
    if (recentEmojiIndex != -1) {
      // Already exist in recent list
      // Remove it
      recentEmoji.removeAt(recentEmojiIndex);
    }
    // Add it first position
    recentEmoji.insert(0, RecentEmoji(emoji, initVal));

    // Limit entries to recentsLimit
    recentEmoji = recentEmoji.sublist(
      0,
      min(config.emojiViewConfig.recentsLimit, recentEmoji.length),
    );

    // save locally
    // final prefs = await SharedPreferences.getInstance();
    // prefs.setString("recent", jsonEncode(recentEmoji));
    await _box.put("recent", jsonEncode(recentEmoji));

    return recentEmoji;
  }

  /// Add an emoji to popular used list or increase its counter
  Future<List<RecentEmoji>> addEmojiToPopularUsed({
    required Emoji emoji,
    Config config = const Config(),
  }) async {
    // Remove emoji's skin tone in Recent-Category
    if (emoji.hasSkinTone) {
      emoji = removeSkinTone(emoji);
    }
    List<RecentEmoji> recentEmoji = await getRecentEmojis();
    final int recentEmojiIndex = recentEmoji.indexWhere(
      (RecentEmoji element) => element.emoji.emoji == emoji.emoji,
    );
    if (recentEmojiIndex != -1) {
      // Already exist in recent list
      // Just update counter
      recentEmoji[recentEmojiIndex].counter++;
    } else if (recentEmoji.length == config.emojiViewConfig.recentsLimit &&
        config.emojiViewConfig.replaceEmojiOnLimitExceed) {
      // Replace latest emoji with the fresh one
      recentEmoji[recentEmoji.length - 1] = RecentEmoji(emoji, initVal);
    } else {
      recentEmoji.add(RecentEmoji(emoji, initVal));
    }

    // Sort by counter desc
    recentEmoji.sort((RecentEmoji a, RecentEmoji b) => b.counter - a.counter);

    // Limit entries to recentsLimit
    recentEmoji = recentEmoji.sublist(
      0,
      min(config.emojiViewConfig.recentsLimit, recentEmoji.length),
    );

    // save locally
    // final prefs = await SharedPreferences.getInstance();
    // prefs.setString("recent", jsonEncode(recentEmoji));
    await _box.put("recent", jsonEncode(recentEmoji));

    return recentEmoji;
  }

  /// Clears the list of recent emojis in local storage
  Future<void> clearRecentEmojisInLocalStorage() async {
    await _box.put("recent", jsonEncode(<String>[]));
  }

  /// Remove skin tone from given emoji
  Emoji removeSkinTone(Emoji emoji) => emoji.copyWith(
        emoji: emoji.emoji.replaceFirst(
          RegExp(SkinTone.values.join("|")),
          "",
        ),
      );
}

late Box<dynamic> _box;

Future<void> _initHive() async {
  const String boxName = "emoji_picker_flutter";
  final Directory directory = await getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  _box = await Hive.openBox<dynamic>(boxName);
}
