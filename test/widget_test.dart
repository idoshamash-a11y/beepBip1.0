// Basic smoke test. Real widget + integration tests should live under
// `test/features/<feature>/` once the architecture layers land.
//
// TODO(tests): add a proper ProviderScope-based smoke test once we have a
// fake AuthRepository / fake Supabase init path. See docs/ARCHITECTURE.md.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    expect(1 + 1, 2);
  });
}
