import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/material.dart";

/// Default Search implementation
class DefaultSearchView extends SearchView {
  /// Constructor
  const DefaultSearchView(
    super.config,
    super.state,
    super.showEmojiView, {
    super.key,
  });

  @override
  DefaultSearchViewState createState() => DefaultSearchViewState();
}

/// Default Search View State
class DefaultSearchViewState extends SearchViewState {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double emojiSize =
              widget.config.emojiViewConfig.getEmojiSize(constraints.maxWidth);
          final double emojiBoxSize = widget.config.emojiViewConfig
              .getEmojiBoxSize(constraints.maxWidth);

          return ColoredBox(
            color: widget.config.searchViewConfig.backgroundColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Material(
                  child: SizedBox(
                    height: emojiBoxSize + 8.0,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      scrollDirection: Axis.horizontal,
                      itemCount: results.length,
                      itemBuilder: (BuildContext context, int index) =>
                          buildEmoji(
                        results[index],
                        emojiSize,
                        emojiBoxSize,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () {
                        widget.showEmojiView();
                      },
                      color: widget.config.searchViewConfig.buttonColor,
                      icon: Icon(
                        Icons.arrow_back,
                        color: widget.config.searchViewConfig.buttonIconColor,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        onChanged: onTextInputChanged,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.config.searchViewConfig.hintText,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}
