import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/material.dart";

/// Default category view
class DefaultCategoryView extends CategoryView {
  /// Constructor
  const DefaultCategoryView(
    super.config,
    super.state,
    super.tabController,
    super.pageController, {
    super.key,
  });

  @override
  DefaultCategoryViewState createState() => DefaultCategoryViewState();
}

/// Default Category View State
class DefaultCategoryViewState extends CategoryViewState {
  @override
  Widget build(BuildContext context) => ColoredBox(
      color: widget.config.categoryViewConfig.backgroundColor,
      child: Row(
        children: <Widget>[
          Expanded(
            child: DefaultCategoryTabBar(
              widget.config,
              widget.tabController,
              widget.pageController,
              widget.state.categoryEmoji,
              closeSkinToneOverlay,
            ),
          ),
          _buildBackspaceButton(),
        ],
      ),
    );

  Widget _buildBackspaceButton() {
    if (widget.config.categoryViewConfig.showBackspaceButton) {
      return BackspaceButton(
        widget.config,
        widget.state.onBackspacePressed,
        widget.state.onBackspaceLongPressed,
        widget.config.categoryViewConfig.backspaceColor,
      );
    }
    return const SizedBox.shrink();
  }
}
