import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

// Use for golden tests, helpful in debugging
// await expectLater(
//   find.byType(MaterialApp),
//   matchesGoldenFile('overlay.png'),
// );

void main() {
  group("EmojiPicker Tests", () {
    testWidgets("Should allow user to select an emoji",
        (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      Emoji? emojiSelected;
      Category? categorySelected;

      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiPicker(
              textEditingController: controller,
              onEmojiSelected: (Category? category, Emoji emoji) {
                emojiSelected = emoji;
                categorySelected = category;
              },
              config: const Config(
                  categoryViewConfig: CategoryViewConfig(
                    recentTabBehavior: RecentTabBehavior.NONE,
                  ),),
            ),
          ),
        ),
      );

      // Wait for the emojis to load if they are being loaded asynchronously
      await tester.pumpAndSettle();

      // Find an emoji in the picker
      final Finder emoji = find.text("🙂").hitTestable();

      // Verify if we can find the emoji
      expect(emoji, findsOneWidget);

      // Tap on the emoji, this should trigger the selection action
      await tester.tap(emoji);

      // Call pumpAndSettle in case the UI needs to settle after an interaction
      await tester.pumpAndSettle();

      // Check if the emoji is added to the text controller
      expect(controller.text, contains("🙂"));

      // Check if the emoji been passed to the 'onEmojiSelected' callback
      expect(
          emojiSelected, equals(const Emoji("🙂", "Slightly Smiling Face")),);

      // Check if the category been passed to the 'onEmojiSelected' callback
      expect(categorySelected, equals(Category.SMILEYS));
    });

    testWidgets("Should allow to select an emoji with skintone on longPress",
        (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      final EmojiPickerUtils utils = EmojiPickerUtils();
      const Emoji emoji = Emoji("👍", "Thumbs Up", hasSkinTone: true);
      Emoji? emojiSelected;
      Category? categorySelected;

      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: EmojiPicker(
                textEditingController: controller,
                onEmojiSelected: (Category? category, Emoji emoji) {
                  emojiSelected = emoji;
                  categorySelected = category;
                },
                config: const Config(
                  height: 500,
                  categoryViewConfig: CategoryViewConfig(
                    recentTabBehavior: RecentTabBehavior.NONE,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Wait for the emojis to load if they are being loaded asynchronously
      await tester.pumpAndSettle();

      // Find an emoji in the picker
      final Finder emojiToFind = find.text(emoji.emoji);

      // Scroll until the emoji to be found appears.
      await tester.dragUntilVisible(
        emojiToFind,
        find.byKey(const Key("emojiScrollView")),
        const Offset(0, -300),
      );

      // Verify if we can find the emoji
      expect(emojiToFind, findsOneWidget);

      // Tap on the emoji, this should trigger the skintone overlay
      await tester.longPress(emojiToFind);

      // Call pumpAndSettle in case the UI needs to settle after an interaction
      await tester.pumpAndSettle();

      /// Check if all skin tones are rendered in overlay
      Finder? skinToneVariantToFind;
      for (int i = 0; i < SkinTone.values.length; i++) {
        skinToneVariantToFind =
            find.text(utils.applySkinTone(emoji, SkinTone.values[i]).emoji);
        // Verify if we can find the skintone variant
        expect(skinToneVariantToFind, findsOneWidget);
      }

      // Tap on the emoji, this should trigger the selection action
      await tester.tap(skinToneVariantToFind!);

      // Check if the emoji is added to the text controller
      expect(controller.text, contains("👍🏿"));

      // Check if the emoji been passed to the 'onEmojiSelected' callback
      expect(emojiSelected?.emoji, equals("👍🏿"));
      expect(emojiSelected?.name, equals("Thumbs Up"));
      expect(emojiSelected?.hasSkinTone, equals(true));

      // Check if the category been passed to the 'onEmojiSelected' callback
      expect(categorySelected, equals(Category.SMILEYS));
    });
  });
}
