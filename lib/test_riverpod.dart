import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyNotifier extends FamilyAsyncNotifier<String, int> {
  @override
  Future<String> build(int arg) async {
    return 'hello $arg';
  }
}
