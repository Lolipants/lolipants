import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/shared/widgets/bottom_nav_bar.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';
import 'package:lolipants/shared/widgets/loading_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _pumpFrame(
    WidgetTester tester, {
    required Widget child,
    Size size = const Size(420, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.ink,
          body: SafeArea(child: child),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shared CTA button golden', (tester) async {
    await _pumpFrame(
      tester,
      child: const RepaintBoundary(
        key: ValueKey('button_golden'),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: LolipantsButton(
              label: 'Continue / متابعة',
              onPressed: null,
              variant: LolipantsButtonVariant.secondary,
              fullWidth: false,
            ),
          ),
        ),
      ),
      size: const Size(360, 240),
    );

    await expectLater(
      find.byKey(const ValueKey('button_golden')),
      matchesGoldenFile('goldens/shared/lolipants_button_secondary.png'),
    );
  });

  testWidgets('shared text field and banner golden', (tester) async {
    await _pumpFrame(
      tester,
      child: const RepaintBoundary(
        key: ValueKey('field_banner_golden'),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LolipantsTextField(
                label: 'Email',
                errorText: 'Invalid email address',
              ),
              SizedBox(height: 12),
              ErrorBanner(
                message: 'Could not complete your request.',
                onDismiss: _noop,
              ),
            ],
          ),
        ),
      ),
      size: const Size(420, 320),
    );

    await expectLater(
      find.byKey(const ValueKey('field_banner_golden')),
      matchesGoldenFile('goldens/shared/field_and_error_banner.png'),
    );
  });

  testWidgets('shared bottom nav and loading overlay golden', (tester) async {
    await _pumpFrame(
      tester,
      child: RepaintBoundary(
        key: const ValueKey('bottom_nav_loading_golden'),
        child: Stack(
          children: [
            const Align(
              alignment: Alignment.bottomCenter,
              child: LolipantsBottomNavBar(
                shellBranchIndex: 2,
                onShellBranchSelected: _onIndexChanged,
              ),
            ),
            const LoadingOverlay(visible: true),
          ],
        ),
      ),
      size: const Size(420, 220),
    );

    await expectLater(
      find.byKey(const ValueKey('bottom_nav_loading_golden')),
      matchesGoldenFile('goldens/shared/bottom_nav_with_loading_overlay.png'),
    );
  });
}

void _noop() {}

void _onIndexChanged(int _) {}
