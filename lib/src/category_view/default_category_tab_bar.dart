import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/material.dart";

/// Default category tab bar
class DefaultCategoryTabBar extends StatelessWidget {
  /// Constructor
  const DefaultCategoryTabBar(
    this.config,
    this.tabController,
    this.pageController,
    this.categoryEmojis,
    this.closeSkinToneOverlay, {
    super.key,
  });

  /// Config
  final Config config;

  /// Tab controller
  final TabController tabController;

  /// Page controller
  final PageController pageController;

  /// Category emojis
  final List<CategoryEmoji> categoryEmojis;

  /// Close skin tone overlay callback
  final VoidCallback closeSkinToneOverlay;

  @override
  Widget build(BuildContext context) => SizedBox(
      height: config.categoryViewConfig.tabBarHeight,
      child: TabBar(
        labelColor: config.categoryViewConfig.iconColorSelected,
        indicatorColor: config.categoryViewConfig.indicatorColor,
        unselectedLabelColor: config.categoryViewConfig.iconColor,
        dividerColor: config.categoryViewConfig.dividerColor,
        controller: tabController,
        labelPadding: EdgeInsets.zero,
        onTap: (int index) {
          closeSkinToneOverlay();
          pageController.jumpToPage(index);
        },
        tabs: categoryEmojis
            .asMap()
            .entries
            .map<Widget>(
                (MapEntry<int, CategoryEmoji> item) => _buildCategoryTab(item.key, item.value.category),)
            .toList(),
      ),
    );

  Widget _buildCategoryTab(int index, Category category) => Tab(
      icon: Icon(
        getIconForCategory(config.categoryViewConfig.categoryIcons, category),
      ),
    );
}
