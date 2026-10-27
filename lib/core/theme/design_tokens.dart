import 'package:flutter/cupertino.dart';

abstract final class AppSpace {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
}

abstract final class AppRadii {
  static const control = 12.0, section = 16.0, card = 24.0;
}

abstract final class AppLayout {
  // A sidebar needs room for readable labels and a useful content pane.
  static const sidebarBreakpoint = 1000.0;
  static const contentWidth = 1040.0, dashboardWidth = 1240.0;
  static const formWidth = 640.0, sidebarWidth = 224.0;

  static double inset(double width, double maximum) => width > maximum + 64
      ? (width - maximum) / 2
      : width >= 700
      ? 32
      : 16;
}

abstract final class AppMotion {
  static const press = Duration(milliseconds: 110);
  static const short = Duration(milliseconds: 180);
  static const reveal = Duration(milliseconds: 280);
  static const chart = Duration(milliseconds: 350);
  static const curve = Curves.easeOutCubic;
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

abstract final class AppType {
  static const page = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );
  static const section = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
  static const caption = TextStyle(fontSize: 13, height: 1.4);
  static const group = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
  );
}
