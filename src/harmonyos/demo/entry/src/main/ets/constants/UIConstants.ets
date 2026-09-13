/**
 * UI Style Constants
 * Centralized UI styling constants to maintain consistency across the application
 */

// Colors
export class AppColors {
  static readonly PRIMARY = '#FF6600';
  static readonly PRIMARY_PRESSED = '#E55C00';
  static readonly PRIMARY_DISABLED = '#CC5200';
  static readonly PRIMARY_SOFT = '#FFF3E8';
  static readonly TEXT_PRIMARY = '#333333';
  static readonly TEXT_SECONDARY = '#666666';
  static readonly TEXT_HINT = '#999999';
  static readonly TEXT_DISABLED = '#CCCCCC';
  static readonly TEXT_INVERSE = '#FFFFFF';
  static readonly ERROR = '#FF0000';
  static readonly ERROR_SOFT = '#FEECEC';
  static readonly SUCCESS = '#4CAF50';
  static readonly SUCCESS_SOFT = '#EAF7EB';
  static readonly INFO = '#2196F3';
  static readonly INFO_SOFT = '#EAF4FF';
  static readonly WARNING = '#F44336';
  static readonly WARNING_SOFT = '#FFF0E0';
  static readonly ORANGE = '#FF9800';
  static readonly PURPLE = '#9C27B0';
  static readonly PURPLE_SOFT = '#F5EAF8';
  static readonly CYAN = '#00BCD4';
  static readonly CYAN_SOFT = '#E8F8FA';
  static readonly INDIGO = '#3F51B5';
  static readonly INDIGO_SOFT = '#EDF0FA';
  static readonly DEEP_PURPLE = '#673AB7';
  static readonly DEEP_PURPLE_SOFT = '#F0EAF8';
  static readonly BACKGROUND = '#F5F5F5';
  static readonly PAGE_BACKGROUND = '#F7F8FA';
  static readonly SURFACE = '#FFFFFF';
  static readonly SURFACE_MUTED = '#FAFAFA';
  static readonly WHITE = '#FFFFFF';
  static readonly DIVIDER = '#E0E0E0';
  static readonly BORDER = '#E7E8EA';
  static readonly LIGHT_GRAY = '#F0F0F0';
  static readonly INPUT_BG = '#F5F5F5';
  static readonly OVERLAY = 'rgba(0, 0, 0, 0.5)';
}

// Font Sizes
export class FontSizes {
  static readonly SMALL = 12;
  static readonly CAPTION = 13;
  static readonly NORMAL = 14;
  static readonly BODY = 15;
  static readonly MEDIUM = 16;
  static readonly LARGE = 18;
  static readonly TITLE = 20;
  static readonly SUBTITLE = 22;
  static readonly HUGE = 24;
}

// Spacing
export class Spacing {
  static readonly XS = 4;
  static readonly SM = 8;
  static readonly MD = 12;
  static readonly LG = 16;
  static readonly XL = 20;
  static readonly XXL = 24;
  static readonly SCREEN_HORIZONTAL = 16;
  static readonly SECTION_GAP = 12;
}

// Border Radius
export class BorderRadius {
  static readonly SMALL = 8;
  static readonly MEDIUM = 12;
  static readonly LARGE = 16;
  static readonly CARD = 8;
  static readonly PILL = 999;
}

// Heights
export class Heights {
  static readonly BUTTON = 44;
  static readonly BUTTON_TALL = 50;
  static readonly TOOLBAR = 56;
  static readonly NAV_BAR = 56;
  static readonly INPUT = 44;
  static readonly INPUT_TALL = 50;
  static readonly ACCESS_TYPE_OPTION = 88;
  static readonly LIST_ITEM = 64;
  static readonly LIST_CELL = 72;
  static readonly TEXT_AREA = 120;
  static readonly FEATURE_ACCENT = 36;
  static readonly TOUCH_TARGET = 44;
}

// Icon Size
export class IconSizes {
  static readonly SMALL = 16;
  static readonly MEDIUM = 22;
  static readonly LARGE = 24;
  static readonly NAV = 28;
  static readonly CELL = 40;
  static readonly XLARGE = 48;
  static readonly AVATAR = 64;
}

export class StrokeWidths {
  static readonly HAIRLINE = 1;
  static readonly ACCENT = 4;
}

// Toast Duration
export class ToastDuration {
  static readonly SHORT = 1000;
  static readonly MEDIUM = 1500;
  static readonly LONG = 2000;
}

// Animation Duration
export class AnimDuration {
  static readonly FAST = 500;
  static readonly MEDIUM = 1000;
  static readonly SLOW = 2000;
  static readonly VERY_SLOW = 3000;
}
