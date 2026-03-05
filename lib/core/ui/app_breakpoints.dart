class AppBreakpoints {
  static const desktop = 1100.0;
  static const tablet = 800.0;
  static const double mobile = 600;

  static bool isDesktop(double w) => w >= desktop;
  static bool isTablet(double w) => w >= tablet && w < desktop;
  static bool isMobile(double w) => w < tablet;
}
