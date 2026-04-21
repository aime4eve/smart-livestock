import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/widgets/pagination_bar.dart';

void main() {
  testWidgets('PaginationBar 显示当前页/总页数', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaginationBar(
          page: 2,
          pageCount: 5,
          onPageChanged: (_) {},
        ),
      ),
    ));
    expect(find.text('2 / 5'), findsOneWidget);
  });

  testWidgets('点击下一页触发 onPageChanged(page+1)', (tester) async {
    int? received;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaginationBar(
          page: 2,
          pageCount: 5,
          onPageChanged: (p) => received = p,
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('pagination-next')));
    expect(received, 3);
  });

  testWidgets('首页时上一页按钮禁用', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaginationBar(
          page: 1,
          pageCount: 5,
          onPageChanged: (_) {},
        ),
      ),
    ));
    final prev = tester.widget<IconButton>(find.byKey(const Key('pagination-prev')));
    expect(prev.onPressed, isNull);
  });
}
