// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

/// A mapping of the unit interval to the unit interval.
///
/// A curve must map t=0.0 to 0.0 and t=1.0 to 1.0.
///
/// See [Curves] for a collection of common animation curves.
abstract class Curve {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Curve();

  /// Returns the value of the curve at point `t`.
  ///
  /// The value of `t` must be between 0.0 and 1.0, inclusive. Subclasses should
  /// assert that this is true.
  ///
  /// A curve must map t=0.0 to 0.0 and t=1.0 to 1.0.
  double transform(double t);

  /// Returns a new curve that is the reversed inversion of this one.
  /// This is often useful as the reverseCurve of an [Animation].
  Curve get flipped => new FlippedCurve(this);

  @override
  String toString() {
    return '$runtimeType';
  }
}

/// The identity map over the unit interval.
///
/// See [Curves.linear] for an instance of this class.
class _Linear extends Curve {
  const _Linear._();

  @override
  double transform(double t) => t;
}

/// A sawtooth curve that repeats a given number of times over the unit interval.
///
/// The curve rises linearly from 0.0 to 1.0 and then falls discontinuously back
/// to 0.0 each iteration.
class SawTooth extends Curve {
  /// Creates a sawtooth curve.
  ///
  /// The [count] argument must not be null.
  const SawTooth(this.count);

  /// The number of repetitions of the sawtooth pattern in the unit interval.
  final int count;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    if (t == 1.0)
      return 1.0;
    t *= count;
    return t - t.truncateToDouble();
  }

  @override
  String toString() {
    return '$runtimeType($count)';
  }
}

/// A curve that is 0.0 until [start], then curved from 0.0 to 1.0 at [end], then 1.0.
class Interval extends Curve {
  /// Creates an interval curve.
  ///
  /// The [start] and [end] arguments must not be null.
  const Interval(this.begin, this.end, { this.curve: Curves.linear });

  /// The smallest value for which this interval is 0.0.
  final double begin;

  /// The smallest value for which this interval is 1.0.
  final double end;

  /// The curve to apply between [start] and [end].
  final Curve curve;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    assert(begin >= 0.0);
    assert(begin <= 1.0);
    assert(end >= 0.0);
    assert(end <= 1.0);
    assert(end >= begin);
    if (t == 0.0 || t == 1.0)
      return t;
    t = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    if (t == 0.0 || t == 1.0)
      return t;
    return curve.transform(t);
  }

  @override
  String toString() {
    if (curve is! _Linear)
      return '$runtimeType($begin\u22EF$end)\u27A9$curve';
    return '$runtimeType($begin\u22EF$end)';
  }
}

/// A curve that is 0.0 until it hits the threshold, then it jumps to 1.0.
class Threshold extends Curve {
  /// Creates a threshold curve.
  ///
  /// The [threshold] argument must not be null.
  const Threshold(this.threshold);

  /// The value before which the curve is 0.0 and after which the curve is 1.0.
  ///
  /// When t is exactly [threshold], the curve has the value 1.0.
  final double threshold;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    assert(threshold >= 0.0);
    assert(threshold <= 1.0);
    if (t == 0.0 || t == 1.0)
      return t;
    return t < threshold ? 0.0 : 1.0;
  }
}

/// A cubic polynomial mapping of the unit interval.
///
/// See [Curves] for a number of commonly used cubic curves.
///
/// See also:
///
///  * [Curves.ease]
///  * [Curves.easeIn]
///  * [Curves.easeOut]
///  * [Curves.easeInOut]
class Cubic extends Curve {
  /// Creates a cubic curve.
  ///
  /// Rather than creating a new instance, consider using one of the common
  /// cubic curves in [Curves].
  ///
  /// The [a], [b], [c], and [d] arguments must not be null.
  const Cubic(this.a, this.b, this.c, this.d);

  /// The x coordinate of the first control point.
  ///
  /// The line through the point (0, 0) and the first control point is tangent
  /// to the curve at the point (0, 0).
  final double a;

  /// The y coordinate of the first control point.
  ///
  /// The line through the point (0, 0) and the first control point is tangent
  /// to the curve at the point (0, 0).
  final double b;

  /// The x coordinate of the second control point.
  ///
  /// The line through the point (1, 1) and the second control point is tangent
  /// to the curve at the point (1, 1).
  final double c;

  /// The y coordinate of the second control point.
  ///
  /// The line through the point (1, 1) and the second control point is tangent
  /// to the curve at the point (1, 1).
  final double d;

  static const double _kCubicErrorBound = 0.001;

  double _evaluateCubic(double a, double b, double m) {
    return 3 * a * (1 - m) * (1 - m) * m +
           3 * b * (1 - m) *           m * m +
                                       m * m * m;
  }

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    double start = 0.0;
    double end = 1.0;
    while (true) {
      double midpoint = (start + end) / 2;
      double estimate = _evaluateCubic(a, c, midpoint);
      if ((t - estimate).abs() < _kCubicErrorBound)
        return _evaluateCubic(b, d, midpoint);
      if (estimate < t)
        start = midpoint;
      else
        end = midpoint;
    }
  }

  @override
  String toString() {
    return '$runtimeType(${a.toStringAsFixed(2)}, ${b.toStringAsFixed(2)}, ${c.toStringAsFixed(2)}, ${d.toStringAsFixed(2)})';
  }
}

/// A curve that is the reversed inversion of its given curve.
///
/// This curve evalutes the given curve in reverse (i.e., from 1.0 to 0.0 as t
/// increases from 0.0 to 1.0) and returns the inverse of the given curve's value
/// (i.e., 1.0 minus the given curve's value).
class FlippedCurve extends Curve {
  /// Creates a flipped curve.
  ///
  /// The [curve] argument must not be null.
  const FlippedCurve(this.curve);

  /// The curve that is being flipped.
  final Curve curve;

  @override
  double transform(double t) => 1.0 - curve.transform(1.0 - t);

  @override
  String toString() {
    return '$runtimeType($curve)';
  }
}

/// A curve where the rate of change starts out quickly and then decelerates; an
/// upside-down `f(t) = t²` parabola.
///
/// This is equivalent to the Android `DecelerateInterpolator` class with a unit
/// factor (the default factor).
///
/// See [Curves.decelerate] for an instance of this class.
class _DecelerateCurve extends Curve {
  const _DecelerateCurve._();

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    // Intended to match the behavior of:
    // https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/view/animation/DecelerateInterpolator.java
    // ...as of December 2016.
    t = 1.0 - t;
    return 1.0 - t * t;
  }
}


// BOUNCE CURVES

double _bounce(double t) {
  if (t < 1.0 / 2.75) {
    return 7.5625 * t * t;
  } else if (t < 2 / 2.75) {
    t -= 1.5 / 2.75;
    return 7.5625 * t * t + 0.75;
  } else if (t < 2.5 / 2.75) {
    t -= 2.25 / 2.75;
    return 7.5625 * t * t + 0.9375;
  }
  t -= 2.625 / 2.75;
  return 7.5625 * t * t + 0.984375;
}

/// An oscillating curve that grows in magnitude.
///
/// See [Curves.bounceIn] for an instance of this class.
class _BounceInCurve extends Curve {
  const _BounceInCurve._();

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    return 1.0 - _bounce(1.0 - t);
  }
}

/// An oscillating curve that shrink in magnitude.
///
/// See [Curves.bounceOut] for an instance of this class.
class _BounceOutCurve extends Curve {
  const _BounceOutCurve._();

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    return _bounce(t);
  }
}

/// An oscillating curve that first grows and then shrink in magnitude.
///
/// See [Curves.bounceInOut] for an instance of this class.
class _BounceInOutCurve extends Curve {
  const _BounceInOutCurve._();

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    if (t < 0.5)
      return (1.0 - _bounce(1.0 - t)) * 0.5;
    else
      return _bounce(t * 2.0 - 1.0) * 0.5 + 0.5;
  }
}


// ELASTIC CURVES

/// An oscillating curve that grows in magnitude while overshooting its bounds.
class ElasticInCurve extends Curve {
  /// Creates an elastic-in curve.
  ///
  /// Rather than creating a new instance, consider using [Curves.elasticIn].
  const ElasticInCurve([this.period = 0.4]);

  /// The duration of the oscillation.
  final double period;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    double s = period / 4.0;
    t = t - 1.0;
    return -math.pow(2.0, 10.0 * t) * math.sin((t - s) * (math.PI * 2.0) / period);
  }

  @override
  String toString() {
    return '$runtimeType($period)';
  }
}

/// An oscillating curve that shrinks in magnitude while overshooting its bounds.
class ElasticOutCurve extends Curve {
  /// Creates an elastic-out curve.
  ///
  /// Rather than creating a new instance, consider using [Curves.elasticOut].
  const ElasticOutCurve([this.period = 0.4]);

  /// The duration of the oscillation.
  final double period;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    double s = period / 4.0;
    return math.pow(2.0, -10 * t) * math.sin((t - s) * (math.PI * 2.0) / period) + 1.0;
  }

  @override
  String toString() {
    return '$runtimeType($period)';
  }
}

/// An oscillating curve that grows and then shrinks in magnitude while overshooting its bounds.
class ElasticInOutCurve extends Curve {
  /// Creates an elastic-in-out curve.
  ///
  /// Rather than creating a new instance, consider using [Curves.elasticInOut].
  const ElasticInOutCurve([this.period = 0.4]);

  /// The duration of the oscillation.
  final double period;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    double s = period / 4.0;
    t = 2.0 * t - 1.0;
    if (t < 0.0)
      return -0.5 * math.pow(2.0, 10.0 * t) * math.sin((t - s) * (math.PI * 2.0) / period);
    else
      return math.pow(2.0, -10.0 * t) * math.sin((t - s) * (math.PI * 2.0) / period) * 0.5 + 1.0;
  }

  @override
  String toString() {
    return '$runtimeType($period)';
  }
}


// PREDEFINED CURVES

/// A collection of common animation curves.
class Curves {
  Curves._();

  /// A linear animation curve.
  ///
  /// This is the identity map over the unit interval: its [Curve.transform]
  /// method returns its input unmodified. This is useful as a default curve for
  /// cases where a [Curve] is required but no actual curve is desired.
  static const Curve linear = const _Linear._();

  /// A curve where the rate of change starts out quickly and then decelerates; an
  /// upside-down `f(t) = t²` parabola.
  ///
  /// This is equivalent to the Android `DecelerateInterpolator` class with a unit
  /// factor (the default factor).
  static const Curve decelerate = const _DecelerateCurve._();

  /// A cubic animation curve that speeds up quickly and ends slowly.
  static const Cubic ease = const Cubic(0.25, 0.1, 0.25, 1.0);

  /// A cubic animation curve that starts slowly and ends quickly.
  static const Cubic easeIn = const Cubic(0.42, 0.0, 1.0, 1.0);

  /// A cubic animation curve that starts quickly and ends slowly.
  static const Cubic easeOut = const Cubic(0.0, 0.0, 0.58, 1.0);

  /// A cubic animation curve that starts slowly, speeds up, and then and ends slowly.
  static const Cubic easeInOut = const Cubic(0.42, 0.0, 0.58, 1.0);

  /// A curve that starts quickly and eases into its final position.
  ///
  /// Over the course of the animation, the object spends more time near its
  /// final destination. As a result, the user isn’t left waiting for the
  /// animation to finish, and the negative effects of motion are minimized.
  static const Cubic fastOutSlowIn = const Cubic(0.4, 0.0, 0.2, 1.0);

  /// An oscillating curve that grows in magnitude.
  static const Curve bounceIn = const _BounceInCurve._();

  /// An oscillating curve that first grows and then shrink in magnitude.
  static const Curve bounceOut = const _BounceOutCurve._();

  /// An oscillating curve that first grows and then shrink in magnitude.
  static const Curve bounceInOut = const _BounceInOutCurve._();

  /// An oscillating curve that grows in magnitude while overshootings its bounds.
  static const ElasticInCurve elasticIn = const ElasticInCurve();

  /// An oscillating curve that shrinks in magnitude while overshootings its bounds.
  static const ElasticOutCurve elasticOut = const ElasticOutCurve();

  /// An oscillating curve that grows and then shrinks in magnitude while overshootings its bounds.
  static const ElasticInOutCurve elasticInOut = const ElasticInOutCurve();
}
