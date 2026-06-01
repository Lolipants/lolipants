import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StackFit.expand gives Positioned.fill non-zero width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 500,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: _WidthProbe(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('400.0'), findsOneWidget);
  });
}

class _WidthProbe extends StatelessWidget {
  const _WidthProbe();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Text('${constraints.maxWidth}');
      },
    );
  }
}
