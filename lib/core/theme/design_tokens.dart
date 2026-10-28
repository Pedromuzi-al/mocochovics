import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

abstract final class AppSpace {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
}

abstract final class AppRadii {
  static const control = 14.0, section = 20.0, card = 28.0;
  static const glass = 36.0;
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
  static const navigation = Duration(milliseconds: 420);
  static const spring = DampedSpringCurve();
  static const curve = Curves.easeOutCubic;
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

/// A critically damped physical response: quick feedback without bouncing data.
class DampedSpringCurve extends Curve {
  const DampedSpringCurve();
  @override
  double transformInternal(double t) => SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 380, damping: 36),
    0,
    1,
    0,
  ).x(t * .48).clamp(0.0, 1.0);
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
