library ffi_system_access;

import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as ffi;
import 'dart:io' show Platform, Directory;
import 'package:path/path.dart' as path;

typedef _SystemAccessC = ffi.Void Function(ffi.Pointer<ffi.Utf8>);
typedef _SystemAccessD = void Function(ffi.Pointer<ffi.Utf8>);

class SystemAccess {
  final _SystemAccessD _systemAccess;

  SystemAccess({String? baseLibraryPath})
      : _systemAccess = _getSystemAccessFunc(
          _getRealLibraryPath(
            baseLibraryPath ?? Directory.current.toString(),
          ),
        );

  static _SystemAccessD _getSystemAccessFunc(String libraryPath) {
    final _dylib = ffi.DynamicLibrary.open(libraryPath);

    return _dylib
        .lookupFunction<_SystemAccessC, _SystemAccessD>("system_access");
  }

  static String _getRealLibraryPath(String baseLibraryPath) {
    if (Platform.isMacOS) {
      return path.join(
        baseLibraryPath,
        'ffi_system_access_library',
        'libffi_system_access.dylib',
      );
    }

    if (Platform.isWindows) {
      return path.join(
        baseLibraryPath,
        'ffi_system_access_library',
        'Debug',
        'ffi_system_access.dll',
      );
    }

    return path.join(
      baseLibraryPath,
      'ffi_system_access_library',
      'libffi_system_access.so',
    );
  }

  void runScript(String script) {
    final scriptToNativeString = script.toNativeUtf8();
    _systemAccess(scriptToNativeString);
    ffi.calloc.free(scriptToNativeString);
  }
}
