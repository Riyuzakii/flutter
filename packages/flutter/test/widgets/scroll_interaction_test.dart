// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Scroll flings twice in a row does not crash', (WidgetTester tester) async {
    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new Container(height: 100000.0)
      ]
    ));

    Scrollable2State scrollable =
      tester.state<Scrollable2State>(find.byType(Scrollable2));

    expect(scrollable.position.pixels, equals(0.0));

    await tester.flingFrom(const Point(200.0, 300.0), const Offset(0.0, -200.0), 500.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(scrollable.position.pixels, greaterThan(0.0));

    double oldOffset = scrollable.position.pixels;

    await tester.flingFrom(const Point(200.0, 300.0), const Offset(0.0, -200.0), 500.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(scrollable.position.pixels, greaterThan(oldOffset));
  });
}
