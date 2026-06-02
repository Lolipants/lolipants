import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/logic/editor_print_reference.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: 'CLOUDFLARE_R2_BASE_URL=https://cdn.example.com\n',
    );
  });
  test('detects catalogue flat URL saved as printImageUrl', () {
    const catalog =
        'assets/images/designs/design_womens_look_gulf_abaya_black_closed.png';
    expect(
      isEditorReferencePrintImage(
        printPathOrUrl:
            'https://cdn.example.com/catalog/designs/design_womens_look_gulf_abaya_black_closed.png',
        catalogDesignPath: catalog,
        renderMetadata: {
          'catalogFlatImageUrl':
              'https://cdn.example.com/catalog/designs/design_womens_look_gulf_abaya_black_closed.png',
        },
      ),
      isTrue,
    );
  });

  test('allows distinct user print on casual flat-lay', () {
    expect(
      isEditorReferencePrintImage(
        printPathOrUrl: 'https://cdn.example.com/prints/my-logo.png',
        catalogDesignPath: kCasualFlatlayPaths.first,
      ),
      isFalse,
    );
  });
}
