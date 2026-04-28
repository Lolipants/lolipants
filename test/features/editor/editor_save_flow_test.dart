import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/editor/data/designs_repository.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/editor/models/fabric_option.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

class _FakeAuthStorage extends AuthLocalStorage {
  @override
  Future<String?> readSessionToken() async => 'token';
}

class _FakeDesignsRepository extends DesignsRepository {
  _FakeDesignsRepository()
      : super(
          dio: Dio(),
          storage: _FakeAuthStorage(),
        );

  Map<String, dynamic>? lastPayload;

  @override
  Future<Either<AppException, String>> uploadPrintImage({
    required String filePath,
  }) async {
    return right('https://cdn.example.com/prints/remote.jpg');
  }

  @override
  Future<Either<AppException, GarmentDesign>> createDesign({
    required Map<String, dynamic> payload,
  }) async {
    lastPayload = payload;
    return right(
      GarmentDesign.fromApi({
        'id': 'design-1',
        'name': payload['name'] ?? 'Untitled',
        'garment_type': payload['garmentType'] ?? 'thobe',
        'primary_colour': payload['primaryColour'] ?? '#162F28',
      }),
    );
  }

  @override
  Future<Either<AppException, List<GarmentDesign>>> getMyDesigns() async {
    return right(const <GarmentDesign>[]);
  }

  @override
  Future<Either<AppException, List<FabricOption>>> getFabricsForGarmentType(
    String garmentType,
  ) async {
    return right(
      const [
        FabricOption(
          id: 'cotton',
          name: 'Cotton',
          nameAr: 'قطن',
          quality: 'standard',
          isAvailable: true,
        ),
      ],
    );
  }
}

void main() {
  test('editor save uploads local print and persists remote url', () async {
    final fakeRepo = _FakeDesignsRepository();
    final container = ProviderContainer(
      overrides: [
        designsRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final tempDir = await Directory.systemTemp.createTemp('lolipants_test');
    addTearDown(() async => tempDir.delete(recursive: true));
    final file = File('${tempDir.path}/print.png');
    await file.writeAsBytes([1, 2, 3, 4]);

    final notifier = container.read(editorProvider.notifier);
    notifier.setDesignName('Save Flow Test');
    notifier.setPrintImagePath(file.path);

    final result = await notifier.saveDesign();

    expect(result.success, isTrue);
    expect(
      container.read(editorProvider).printImagePath,
      'https://cdn.example.com/prints/remote.jpg',
    );
    expect(
      fakeRepo.lastPayload?['printImageUrl'],
      'https://cdn.example.com/prints/remote.jpg',
    );
  });

  test('text placement persists in save payload after move', () async {
    final fakeRepo = _FakeDesignsRepository();
    final container = ProviderContainer(
      overrides: [
        designsRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(editorProvider.notifier);
    notifier.setDesignName('Text Move Test');
    notifier.addTextLayer('Hello');
    final state = container.read(editorProvider);
    notifier.selectTextLayer(state.textLayers.first.id);
    notifier.updateSelectedText(placement: const Offset(0.63, 0.42));

    final result = await notifier.saveDesign();
    expect(result.success, isTrue);

    final layers = fakeRepo.lastPayload?['textLayers'] as List<dynamic>;
    final first = layers.first as Map<String, dynamic>;
    expect(first['x'], 0.63);
    expect(first['y'], 0.42);
  });
}
