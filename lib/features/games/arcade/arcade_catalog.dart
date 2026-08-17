/// Touch Arcade mini-game kinds and category slug mapping.
enum ArcadeKind {
  speedTap,
  spatialGrid,
  swipeFocus;

  String get path => switch (this) {
        ArcadeKind.speedTap => 'speed-tap',
        ArcadeKind.spatialGrid => 'spatial-grid',
        ArcadeKind.swipeFocus => 'swipe-focus',
      };

  String get titleKey => switch (this) {
        ArcadeKind.speedTap => 'arcade_speed_tap',
        ArcadeKind.spatialGrid => 'arcade_spatial_grid',
        ArcadeKind.swipeFocus => 'arcade_swipe_focus',
      };

  String get rulesKey => switch (this) {
        ArcadeKind.speedTap => 'arcade_speed_tap_rules',
        ArcadeKind.spatialGrid => 'arcade_spatial_grid_rules',
        ArcadeKind.swipeFocus => 'arcade_swipe_focus_rules',
      };

  static ArcadeKind? tryParse(String? raw) {
    return switch (raw) {
      'speed-tap' || 'speedTap' => ArcadeKind.speedTap,
      'spatial-grid' || 'spatialGrid' => ArcadeKind.spatialGrid,
      'swipe-focus' || 'swipeFocus' => ArcadeKind.swipeFocus,
      _ => null,
    };
  }

  /// Maps backend / local category slugs onto arcade engines.
  static ArcadeKind? forSlug(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    return switch (slug.toLowerCase()) {
      'hizli-matematik' || 'quick_math' || 'quickmath' => ArcadeKind.speedTap,
      'oruntu-yakalama' || 'pattern' => ArcadeKind.spatialGrid,
      'go-nogo' || 'go_nogo' || 'gonogo' => ArcadeKind.swipeFocus,
      _ => null,
    };
  }

  static String routeFor({
    required ArcadeKind kind,
    required int categoryId,
    required String slug,
    required String title,
  }) {
    final q = {
      'categoryId': '$categoryId',
      'slug': slug,
      'title': title,
    }.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    return '/dashboard/arcade/${kind.path}?$q';
  }
}
