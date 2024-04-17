import "dart:collection";

import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/material.dart";

/// Skin tone overlay mixin
mixin SkinToneOverlayStateMixin<T extends StatefulWidget> on State<T> {
  final EmojiPickerUtils _utils = EmojiPickerUtils();
  OverlayEntry? _overlay;

  /// Layer links for skin tone overlay
  final HashMap<String, LayerLink> links = HashMap<String, LayerLink>();

  /// Add target for skin tone overlay if skin tone is available
  Widget addSkinToneTargetIfAvailable({
    required bool hasSkinTone,
    required String linkKey,
    required Widget child,
  }) {
    if (hasSkinTone) {
      final LayerLink link = links.putIfAbsent(linkKey, LayerLink.new);
      return CompositedTransformTarget(
        link: link,
        child: child,
      );
    }
    return child;
  }

  /// Overlay close & resources disposal
  void closeSkinToneOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  /// Overlay for SkinTone
  void showSkinToneOverlay(
    Offset emojiBoxPosition,
    Emoji emoji,
    double emojiSize,
    CategoryEmoji? categoryEmoji,
    Config config,
    OnEmojiSelected onEmojiSelected,
    LayerLink link,
  ) {
    // Generate other skintone options
    final List<Emoji> skinTonesEmoji = SkinTone.values
        .map((String skinTone) => _utils.applySkinTone(emoji, skinTone))
        .toList();

    final double screenWidth = MediaQuery.of(context).size.width;
    final RenderBox emojiPickerRenderbox = context.findRenderObject()! as RenderBox;
    final double emojiBoxSize = config.emojiViewConfig.getEmojiBoxSize(
      emojiPickerRenderbox.size.width,
    );
    final double left = _calculateLeftOffset(
      emojiBoxSize,
      emojiBoxPosition,
      screenWidth,
    );
    final double top = _calculateTopOffset(emojiBoxSize);

    _overlay = OverlayEntry(
      builder: (BuildContext context) => Positioned(
        top: 0,
        left: 0,
        child: CompositedTransformFollower(
          offset: Offset(left, top),
          link: link,
          showWhenUnlinked: false,
          child: TapRegion(
            onTapOutside: (_) => closeSkinToneOverlay(),
            child: Material(
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: config.skinToneConfig.dialogBackgroundColor,
                child: Row(
                  children: <Widget>[
                    EmojiCell.fromConfig(
                      emoji: emoji,
                      emojiSize: emojiSize,
                      emojiBoxSize: emojiBoxSize,
                      categoryEmoji: categoryEmoji,
                      onEmojiSelected: onEmojiSelected,
                      config: config,
                    ),
                    ...List.generate(
                      SkinTone.values.length,
                      (int index) => EmojiCell.fromConfig(
                        emoji: skinTonesEmoji[index],
                        emojiSize: emojiSize,
                        emojiBoxSize: emojiBoxSize,
                        categoryEmoji: categoryEmoji,
                        onEmojiSelected: onEmojiSelected,
                        config: config,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (_overlay != null) {
      Overlay.of(context).insert(_overlay!);
    } else {
      throw Exception("Nullable skin tone overlay insert attempt");
    }
  }

  double _calculateTopOffset(double emojiBoxSize) {
    const double verticalPaddingOverlay = 8;
    final double top = -emojiBoxSize - verticalPaddingOverlay;
    return top;
  }

  double _calculateLeftOffset(
    double emojiBoxSize,
    Offset emojiBoxPosition,
    double screenWidth,
  ) {
    double left = -2.5 * emojiBoxSize;

    if (emojiBoxPosition.dx - 1 * emojiBoxSize < 0) {
      left += 2.5 * emojiBoxSize;
    } else if (emojiBoxPosition.dx - 2 * emojiBoxSize < 0) {
      left += 1.5 * emojiBoxSize;
    } else if (emojiBoxPosition.dx - 3 * emojiBoxSize < 0) {
      left += 0.5 * emojiBoxSize;
    } else if (emojiBoxPosition.dx + 2 * emojiBoxSize > screenWidth) {
      left -= 2.5 * emojiBoxSize;
    } else if (emojiBoxPosition.dx + 3 * emojiBoxSize > screenWidth) {
      left -= 1.5 * emojiBoxSize;
    } else if (emojiBoxPosition.dx + 4 * emojiBoxSize > screenWidth) {
      left -= 0.5 * emojiBoxSize;
    }
    return left;
  }

  @override
  void dispose() {
    _overlay?.dispose();
    super.dispose();
  }
}
