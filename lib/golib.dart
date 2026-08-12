import 'dart:developer' as developer;
import 'dart:ffi';
import 'package:ffi/ffi.dart';

/// FFI bindings for the Go shared library `libgolib.so`.
///
/// The `.so` is cross-compiled from Go (GOOS=openharmony GOARCH=arm64) and
/// packaged into `ohos/entry/libs/arm64-v8a/`, which the OHOS linker searches
/// at runtime, so we can open it by bare name.
class Golib {
  Golib._() {
    _lib = DynamicLibrary.open('libgolib.so');
    _goSum = _lib.lookupFunction<Int32 Function(Int32, Int32),
        int Function(int, int)>('GoSum');
    _goGreeting = _lib
        .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
      'GoGreeting',
    );
    _goFree = _lib.lookupFunction<Void Function(Pointer<Void>),
        void Function(Pointer<Void>)>('GoFree');
    developer.log('loaded libgolib.so and resolved symbols', name: 'GoFFI');
  }

  /// Singleton; opens the library on first access.
  static final Golib instance = Golib._();

  late final DynamicLibrary _lib;
  late final int Function(int, int) _goSum;
  late final Pointer<Utf8> Function() _goGreeting;
  late final void Function(Pointer<Void>) _goFree;

  /// Calls Go's `GoSum(a, b)`.
  int sum(int a, int b) => _goSum(a, b);

  /// Calls Go's `GoGreeting()` and frees the returned C string.
  String greeting() {
    final Pointer<Utf8> ptr = _goGreeting();
    try {
      return ptr.toDartString();
    } finally {
      _goFree(ptr.cast<Void>());
    }
  }
}
