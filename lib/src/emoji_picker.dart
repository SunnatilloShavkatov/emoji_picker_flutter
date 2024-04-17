// ignore_for_file: discarded_futures

import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:emoji_picker_flutter/src/emoji_picker_internal_utils.dart";
import "package:flutter/material.dart";

/// All the possible categories that [Emoji] can be put into
///
/// All [Category] are shown in the category bar
enum Category {
  /// Recent / Popular emojis
  RECENT,

  /// Smiley emojis
  SMILEYS,

  /// Animal emojis
  ANIMALS,

  /// Food emojis
  FOODS,

  /// Activity emojis
  ACTIVITIES,

  /// Travel emojis
  TRAVEL,

  /// Ojects emojis
  OBJECTS,

  /// Sumbol emojis
  SYMBOLS,

  /// Flag emojis
  FLAGS,
}

/// Extension on Category enum to get its name
extension CategoryExtension on Category {
  /// Returns name of Category
  String get name {
    switch (this) {
      case Category.RECENT:
        return "recent";
      case Category.SMILEYS:
        return "smileys";
      case Category.ANIMALS:
        return "animals";
      case Category.FOODS:
        return "foods";
      case Category.ACTIVITIES:
        return "activities";
      case Category.TRAVEL:
        return "travel";
      case Category.OBJECTS:
        return "objects";
      case Category.SYMBOLS:
        return "symbols";
      case Category.FLAGS:
        return "flags";
    }
  }
}

/// Enum to alter the keyboard button style
enum ButtonMode {
  /// No cell touch effects, uses GestureDetector only. Provides best grid
  /// scrolling performance
  NONE,

  /// Android button style - gives the button a splash color with ripple effect
  MATERIAL,

  /// iOS button style - gives the button a fade out effect when pressed
  CUPERTINO
}

/// Callback function for when emoji is selected
///
/// The function returns the selected [Emoji] as well
/// as the [Category] from which it originated
/// Category can be null in some cases, for example in search results
typedef OnEmojiSelected = void Function(Category? category, Emoji emoji);

/// Callback from emoji cell to show a skin tone selection overlay
typedef OnSkinToneDialogRequested = void Function(
  Offset emojiBoxPosition,
  Emoji emoji,
  double emojiSize,
  CategoryEmoji? categoryEmoji,
);

/// Callback function for backspace button
typedef OnBackspacePressed = void Function();

/// Callback function for backspace button when long pressed
typedef OnBackspaceLongPressed = void Function();

/// The Emoji Keyboard widget
///
/// This widget displays a grid of [Emoji] sorted by [Category]
/// which the user can horizontally scroll through.
///
/// There is also a bottombar which displays all the possible [Category]
/// and allow the user to quickly switch to that [Category]
class EmojiPicker extends StatefulWidget {
  /// EmojiPicker for flutter
  const EmojiPicker({
    super.key,
    this.textEditingController,
    this.scrollController,
    this.onEmojiSelected,
    this.onBackspacePressed,
    this.config = const Config(),
    this.customWidget,
  });

  /// Custom widget
  final EmojiViewBuilder? customWidget;

  /// If you provide the [TextEditingController] that is linked to a
  /// [TextField] this widget handles inserting and deleting for you
  /// automatically.
  final TextEditingController? textEditingController;

  /// If you provide the [ScrollController] that is linked to a
  /// [TextField] this widget handles auto scrolling for you.
  final ScrollController? scrollController;

  /// The function called when the emoji is selected
  final OnEmojiSelected? onEmojiSelected;

  /// The function called when backspace button is pressed
  final OnBackspacePressed? onBackspacePressed;

  /// Config for customizations
  final Config config;

  @override
  EmojiPickerState createState() => EmojiPickerState();
}

/// EmojiPickerState
class EmojiPickerState extends State<EmojiPicker> {
  final List<CategoryEmoji> _categoryEmoji =
      List<CategoryEmoji>.empty(growable: true);
  List<RecentEmoji> _recentEmoji = List<RecentEmoji>.empty(growable: true);
  late EmojiViewState _state;

  // Prevent emojis to be reloaded with every build
  bool _loaded = false;

  // Display Search bar
  bool _isSearchBarVisible = false;

  // Internal helper
  late final EmojiPickerInternalUtils _emojiPickerInternalUtils;

  /// Update recentEmoji list from outside using EmojiPickerUtils
  void updateRecentEmoji(
    List<RecentEmoji> recentEmoji, {
    bool refresh = false,
  }) {
    _recentEmoji = recentEmoji;
    final int recentTabIndex = _categoryEmoji.indexWhere(
        (CategoryEmoji element) => element.category == Category.RECENT);
    if (recentTabIndex != -1) {
      _categoryEmoji[recentTabIndex] = _categoryEmoji[recentTabIndex].copyWith(
          emoji: _recentEmoji.map((RecentEmoji e) => e.emoji).toList());
      if (mounted && refresh) {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _updateEmojis();
    widget.textEditingController?.addListener(_scrollToCursorAfterTextChange);
  }

  @override
  void didUpdateWidget(covariant EmojiPicker oldWidget) {
    if (oldWidget.config != widget.config) {
      // Config changed - rebuild EmojiPickerView completely
      _loaded = false;
      _updateEmojis();
    }
    _resetStateWhenOffstage();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return widget.config.emojiViewConfig.loadingIndicator;
    }
    if (_isSearchBarVisible) {
      return _buildSearchBar();
    }
    return _buildEmojiView();
  }

  void _resetStateWhenOffstage() {
    final Offstage? offstageParent =
        context.findAncestorWidgetOfExactType<Offstage>();
    if (offstageParent != null &&
        offstageParent.offstage &&
        _isSearchBarVisible) {
      setState(() {
        _isSearchBarVisible = false;
      });
    }
  }

  void _onBackspacePressed() {
    if (widget.textEditingController != null) {
      final TextEditingController controller = widget.textEditingController!;

      final String text = controller.value.text;
      int cursorPosition = controller.selection.base.offset;

      // If cursor is not set, then place it at the end of the textfield
      if (cursorPosition < 0) {
        controller.selection = TextSelection(
          baseOffset: controller.text.length,
          extentOffset: controller.text.length,
        );
        cursorPosition = controller.selection.base.offset;
      }

      if (cursorPosition >= 0) {
        final TextSelection selection = controller.value.selection;
        final String newTextBeforeCursor =
            selection.textBefore(text).characters.skipLast(1).toString();

        controller.value = controller.value.copyWith(
          text: newTextBeforeCursor + selection.textAfter(text),
          selection: TextSelection.fromPosition(
            TextPosition(offset: newTextBeforeCursor.length),
          ),
          composing: TextRange.collapsed(newTextBeforeCursor.length),
        );
      }
    }

    widget.onBackspacePressed?.call();

    if (widget.textEditingController == null) {
      _scrollToCursorAfterTextChange();
    }
  }

  void _onBackspaceLongPressed() {
    if (widget.textEditingController != null) {
      final TextEditingController controller = widget.textEditingController!;

      final String text = controller.value.text;
      int cursorPosition = controller.selection.base.offset;

      // If cursor is not set, then place it at the end of the textfield
      if (cursorPosition < 0) {
        controller.selection = TextSelection(
          baseOffset: controller.text.length,
          extentOffset: controller.text.length,
        );
        cursorPosition = controller.selection.base.offset;
      }

      if (cursorPosition >= 0) {
        final TextSelection selection = controller.value.selection;
        final String newTextBeforeCursor = _deleteWordByWord(
          selection.textBefore(text),
        );
        controller.value = controller.value.copyWith(
          text: newTextBeforeCursor + selection.textAfter(text),
          selection: TextSelection.fromPosition(
            TextPosition(offset: newTextBeforeCursor.length),
          ),
          composing: TextRange.collapsed(newTextBeforeCursor.length),
        );
      }
    }
  }

  String _deleteWordByWord(String text) {
    // Trim trailing spaces
    text = text.trimRight();

    // Find the last space to determine the start of the last word
    final int lastSpaceIndex = text.lastIndexOf(" ");

    // If there is a space, remove the last word and spaces before it
    if (lastSpaceIndex != -1) {
      return text.substring(0, lastSpaceIndex).trimRight();
    }

    // If there is no space, remove the entire text
    return "";
  }

  // Add recent emoji handling to tap listener
  void _onEmojiSelected(Category? category, Emoji emoji) {
    if (widget.config.categoryViewConfig.recentTabBehavior ==
        RecentTabBehavior.POPULAR) {
      _emojiPickerInternalUtils
          .addEmojiToPopularUsed(emoji: emoji, config: widget.config)
          .then(
            (List<RecentEmoji> newRecentEmoji) => <void>{
              // we don't want to rebuild the widget if user is currently on
              // the RECENT tab, it will make emojis jump since sorting
              // is based on the use frequency
              updateRecentEmoji(
                newRecentEmoji,
                refresh: category != Category.RECENT,
              ),
            },
          );
    } else if (widget.config.categoryViewConfig.recentTabBehavior ==
        RecentTabBehavior.RECENT) {
      _emojiPickerInternalUtils
          .addEmojiToRecentlyUsed(emoji: emoji, config: widget.config)
          .then(
            (List<RecentEmoji> newRecentEmoji) => <void>{
              // we don't want to rebuild the widget if user is currently on
              // the RECENT tab, it will make emojis jump since sorting
              // is based on the use frequency
              updateRecentEmoji(
                newRecentEmoji,
                refresh: category != Category.RECENT,
              ),
            },
          );
    }

    if (widget.textEditingController != null) {
      // based on https://stackoverflow.com/a/60058972/10975692
      final TextEditingController controller = widget.textEditingController!;
      final String text = controller.text;
      final TextSelection selection = controller.selection;
      final int cursorPosition = controller.selection.base.offset;

      if (cursorPosition < 0) {
        controller.text += emoji.emoji;
        widget.onEmojiSelected?.call(category, emoji);
        return;
      }

      final String newText = text.replaceRange(
        selection.start,
        selection.end,
        emoji.emoji,
      );
      final int emojiLength = emoji.emoji.length;
      controller.value = controller.value.copyWith(
        text: newText,
        selection: selection.copyWith(
          baseOffset: selection.start + emojiLength,
          extentOffset: selection.start + emojiLength,
        ),
        composing: TextRange.collapsed(newText.length),
      );
    }

    widget.onEmojiSelected?.call(category, emoji);

    if (widget.textEditingController == null) {
      _scrollToCursorAfterTextChange();
    }
  }

  // Initialize emoji data
  Future<void> _updateEmojis() async {
    _emojiPickerInternalUtils = await EmojiPickerInternalUtils.getInstance();
    _categoryEmoji.clear();
    if (<RecentTabBehavior>[RecentTabBehavior.RECENT, RecentTabBehavior.POPULAR]
        .contains(widget.config.categoryViewConfig.recentTabBehavior)) {
      _recentEmoji = await _emojiPickerInternalUtils.getRecentEmojis();
      final List<Emoji> recentEmojiMap =
          _recentEmoji.map((RecentEmoji e) => e.emoji).toList();
      _categoryEmoji.add(CategoryEmoji(Category.RECENT, recentEmojiMap));
    }
    final List<CategoryEmoji> data = widget.config.emojiSet;
    _categoryEmoji.addAll(
      widget.config.checkPlatformCompatibility
          ? await _emojiPickerInternalUtils.filterUnsupported(data)
          : data,
    );
    _state = EmojiViewState(
      _categoryEmoji,
      _onEmojiSelected,
      _onBackspacePressed,
      _onBackspaceLongPressed,
    );
    if (mounted) {
      setState(() {
        _loaded = true;
      });
    }
  }

  Widget _buildSearchBar() =>
      widget.config.searchViewConfig.customSearchView == null
          ? DefaultSearchView(
              widget.config,
              _state,
              _hideSearchView,
            )
          : widget.config.searchViewConfig.customSearchView!(
              widget.config,
              _state,
              _hideSearchView,
            );

  Widget _buildEmojiView() => SizedBox(
        height: widget.config.height,
        child: widget.customWidget == null
            ? DefaultEmojiPickerView(
                widget.config,
                _state,
                _showSearchView,
              )
            : widget.customWidget!(
                widget.config,
                _state,
                _showSearchView,
              ),
      );

  void _showSearchView() {
    setState(() {
      _isSearchBarVisible = true;
    });
  }

  void _hideSearchView() {
    setState(() {
      _isSearchBarVisible = false;
    });
  }

  void _scrollToCursorAfterTextChange() {
    if (widget.scrollController != null) {
      final ScrollController scrollController = widget.scrollController!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
          );
        }
      });
    }
  }
}
