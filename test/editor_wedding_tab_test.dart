import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/editor_panel_tabs.dart';
import 'package:lolipants/features/editor/widgets/editor_studio_prompt_card.dart';

void main() {
  testWidgets('Wedding tab hides AI prompt card on editor shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final editor = ref.watch(editorProvider);
                final notifier = ref.read(editorProvider.notifier);
                return Column(
                  children: [
                    if (!editor.isWeddingTab && kFeatureAiEditorTab)
                      EditorStudioPromptCard(
                        onGenerate: () async {},
                      ),
                    if (kFeatureWeddingTab || kFeatureConfiguratorBuild)
                      EditorPanelTabs(
                        activeTab: editor.activeTab,
                        onTabChanged: notifier.setTab,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Wedding'), findsOneWidget);
    expect(find.byType(EditorStudioPromptCard), findsOneWidget);

    await tester.tap(find.text('Wedding'));
    await tester.pumpAndSettle();

    expect(find.byType(EditorStudioPromptCard), findsNothing);
  });
}
