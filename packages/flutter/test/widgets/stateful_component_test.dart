// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'test_widgets.dart';

void main() {
  testWidgets('Stateful widget smoke test', (WidgetTester tester) async {

    void checkTree(BoxDecoration expectedDecoration) {
      SingleChildRenderObjectElement element = tester.element(
        find.byElementPredicate((Element element) => element is SingleChildRenderObjectElement)
      );
      expect(element, isNotNull);
      expect(element.renderObject is RenderDecoratedBox, isTrue);
      RenderDecoratedBox renderObject = element.renderObject;
      expect(renderObject.decoration, equals(expectedDecoration));
    }

    await tester.pumpWidget(
      new FlipWidget(
        left: new DecoratedBox(decoration: kBoxDecorationA),
        right: new DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    checkTree(kBoxDecorationA);

    await tester.pumpWidget(
      new FlipWidget(
        left: new DecoratedBox(decoration: kBoxDecorationB),
        right: new DecoratedBox(decoration: kBoxDecorationA)
      )
    );

    checkTree(kBoxDecorationB);

    flipStatefulWidget(tester);

    await tester.pump();

    checkTree(kBoxDecorationA);

    await tester.pumpWidget(
      new FlipWidget(
        left: new DecoratedBox(decoration: kBoxDecorationA),
        right: new DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    checkTree(kBoxDecorationB);
  });

  testWidgets('Don\'t rebuild subwidgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      new FlipWidget(
        key: const Key('rebuild test'),
        left: new TestBuildCounter(),
        right: new DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    expect(TestBuildCounter.buildCount, equals(1));

    flipStatefulWidget(tester);

    await tester.pump();

    expect(TestBuildCounter.buildCount, equals(1));
  });
}
