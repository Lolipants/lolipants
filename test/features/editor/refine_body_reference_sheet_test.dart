import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/refine_body_reference_sheet.dart';

void main() {
  test('setCustomMannequinImagePath clears photo for mannequin refine path', () {
    final container = ProviderContainer(
      overrides: [
        designCatalogLookupProvider.overrideWithValue(const {}),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(editorProvider.notifier);
    notifier.setCustomMannequinImagePath('/tmp/body-ref.jpg');
    expect(
      container.read(editorProvider).customMannequinImagePath,
      '/tmp/body-ref.jpg',
    );

    notifier.setCustomMannequinImagePath(null);
    expect(container.read(editorProvider).customMannequinImagePath, isNull);
  });

  testWidgets('refine body reference sheet returns mannequin choice',
      (tester) async {
    RefineBodyReference? result;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: _SheetHarness(
            onResult: (value) => result = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.refineBodyReferenceTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.refineBodyReferenceMannequin));
    await tester.pumpAndSettle();

    expect(result, RefineBodyReference.mannequin);
  });

  testWidgets('refine body reference sheet returns custom photo choice',
      (tester) async {
    RefineBodyReference? result;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: _SheetHarness(
            onResult: (value) => result = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.mannequinUploadPhotoCta));
    await tester.pumpAndSettle();

    expect(result, RefineBodyReference.customPhoto);
  });
}

class _SheetHarness extends ConsumerWidget {
  const _SheetHarness({required this.onResult});

  final ValueChanged<RefineBodyReference?> onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            final value = await showRefineBodyReferenceSheet(context, ref);
            onResult(value);
          },
          child: const Text('Open sheet'),
        ),
      ),
    );
  }
}
