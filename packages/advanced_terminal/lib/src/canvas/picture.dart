import 'dart:math';

import '../style/style.dart';

abstract class Graphic {
  TerminalStyle? drawStyle(double x, double y);

  const Graphic();
}

class Filled extends Graphic {
  final TerminalStyle style;

  const Filled({required this.style});

  @override
  TerminalStyle? drawStyle(double x, double y) {
    return style;
  }
}

abstract class Shape {
  const Shape();

  bool inShape(double x, double y);
}

class Circle extends Shape {
  const Circle();

  @override
  bool inShape(double x, double y) =>
      sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2)) <= 0.5;
}

class Triangle extends Shape {
  final Point<double> a, b, c;

  const Triangle(this.a, this.b, this.c);

  @override
  bool inShape(double x, double y) {
    x -= a.x;
    y -= a.y;
    final abx = b.x - a.x;
    final acx = c.x - a.x;
    final aby = b.y - a.y;
    final acy = c.y - a.y;
    double t = double.maxFinite;
    double s = double.maxFinite;

    if (abx == 0) {
      t = x / acx;
    } else if (acx == 0) {
      s = x / abx;
    }

    if (aby == 0) {
      t = x / acy;
    } else if (acy == 0) {
      s = x / aby;
    }

    if (t != double.maxFinite) {
      if (s != double.maxFinite) {
        return _sAndTConditions(s, t);
      }
      if (abx == 0) {
        s = (y - acy * t) / aby;
      } else {
        s = (x - acx * t) / abx;
      }
      return _sAndTConditions(s, t);
    } else if(s != double.maxFinite) {
      if(abx == 0) {
        t = (y - aby * s) / acy;
      } else {
        t = (x - abx * s) / acx;
      }
      return _sAndTConditions(s, t);
    }

    t = (y - x) / (acy / aby - acx / abx);
    s = (-acx*t + x) / abx;
    return _sAndTConditions(s, t);
  }

  bool _sAndTConditions(double s, double t) {
    final c = s >= 0 && t >= 0 && s + t <= 1;
    return c;
  }
}

class And extends Shape {
  final Shape a, b;

  const And(this.a, this.b);

  @override
  bool inShape(double x, double y) => a.inShape(x, y) && a.inShape(x, y);
}

class Xor extends Shape {
  final Shape a, b;

  const Xor(this.a, this.b);

  @override
  bool inShape(double x, double y) => a.inShape(x, y) != a.inShape(x, y);
}

class Not extends Shape {
  final Shape child;

  const Not(this.child);

  @override
  bool inShape(double x, double y) => !child.inShape(x, y);
}

class Or extends Shape {
  final Shape a, b;

  const Or(this.a, this.b);

  @override
  bool inShape(double x, double y) => a.inShape(x, y) || b.inShape(x, y);
}

class Combine extends Shape {
  final List<Shape> children;

  const Combine(this.children);

  @override
  bool inShape(double x, double y) {
    for (final child in children) {
      if (child.inShape(x, y)) {
        return true;
      }
    }
    return false;
  }
}

class Stack implements Graphic {
  final List<Graphic> children;

  const Stack({required this.children});

  @override
  TerminalStyle? drawStyle(double x, double y) {
    for (var i = children.length - 1; i >= 0; i--) {
      final style = children[i].drawStyle(x, y);
      if (style != null) return style;
    }
    return null;
  }
}

class EdgeInsets {
  final double left, right, top, bottom;

  double get contentWidth => 1 - left - right;
  double get contentHeight => 1 - top - bottom;

  double get horizontal => left + right;
  double get vertical => top + bottom;

  const EdgeInsets.lrtb(this.left, this.right, this.top, this.bottom)
      : assert(left >= 0),
        assert(right >= 0),
        assert(top >= 0),
        assert(bottom >= 0),
        assert(left + right < 1),
        assert(top + bottom < 1);

  const EdgeInsets.only({
    this.left = 0,
    this.right = 0,
    this.top = 0,
    this.bottom = 0,
  })  : assert(left >= 0),
        assert(right >= 0),
        assert(top >= 0),
        assert(bottom >= 0),
        assert(left + right < 1),
        assert(top + bottom < 1);

  const EdgeInsets.all(double all)
      : assert(all >= 0 && all < 1),
        left = all,
        right = all,
        top = all,
        bottom = all;

  const EdgeInsets.symmetric({double horizontal = 0, double vertical = 0})
      : assert(horizontal >= 0 && horizontal < 1),
        assert(vertical >= 0 && vertical < 1),
        left = horizontal,
        right = horizontal,
        top = vertical,
        bottom = vertical;
}

class Padding extends Graphic {
  final Graphic child;
  final EdgeInsets edgeInsets;

  const Padding({required this.edgeInsets, required this.child});

  @override
  TerminalStyle? drawStyle(double x, double y) {
    if ((x <= edgeInsets.left || 1 - x <= edgeInsets.right) ||
        (y <= edgeInsets.top || 1 - y <= edgeInsets.bottom)) return null;
    return child.drawStyle(
      (x - edgeInsets.left) / edgeInsets.contentWidth,
      (y - edgeInsets.top) / edgeInsets.contentHeight,
    );
  }
}

class Zoom extends Graphic {
  final Graphic child;
  final EdgeInsets edgeInsets;

  Zoom({required this.edgeInsets, required this.child});

  @override
  TerminalStyle? drawStyle(double x, double y) => child.drawStyle(
        (x + edgeInsets.left) * edgeInsets.contentWidth,
        (y + edgeInsets.top) * edgeInsets.contentHeight,
      );
}

class Clip extends Graphic {
  final Shape shape;
  final Graphic child;
  final bool _shouldBeInShape;

  const Clip({
    required this.shape,
    required this.child,
  }) : _shouldBeInShape = true;

  const Clip.reverse({
    required this.shape,
    required this.child,
  }) : _shouldBeInShape = false;

  @override
  TerminalStyle? drawStyle(double x, double y) {
    if (_shouldBeInShape == shape.inShape(x, y)) {
      return child.drawStyle(x, y);
    }
    return null;
  }
}
