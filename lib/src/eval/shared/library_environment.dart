/// Host SDK library flags, read at compilation time so conditional imports
/// and evaluated environment constructors agree on the selected platform.
const sdkLibraryEnvironment = <String, String>{
  if (bool.hasEnvironment('dart.library.async'))
    'dart.library.async': String.fromEnvironment('dart.library.async'),
  if (bool.hasEnvironment('dart.library.collection'))
    'dart.library.collection': String.fromEnvironment(
      'dart.library.collection',
    ),
  if (bool.hasEnvironment('dart.library.convert'))
    'dart.library.convert': String.fromEnvironment('dart.library.convert'),
  if (bool.hasEnvironment('dart.library.core'))
    'dart.library.core': String.fromEnvironment('dart.library.core'),
  if (bool.hasEnvironment('dart.library.developer'))
    'dart.library.developer': String.fromEnvironment('dart.library.developer'),
  if (bool.hasEnvironment('dart.library.ffi'))
    'dart.library.ffi': String.fromEnvironment('dart.library.ffi'),
  if (bool.hasEnvironment('dart.library.isolate'))
    'dart.library.isolate': String.fromEnvironment('dart.library.isolate'),
  if (bool.hasEnvironment('dart.library.math'))
    'dart.library.math': String.fromEnvironment('dart.library.math'),
  if (bool.hasEnvironment('dart.library.mirrors'))
    'dart.library.mirrors': String.fromEnvironment('dart.library.mirrors'),
  if (bool.hasEnvironment('dart.library.typed_data'))
    'dart.library.typed_data': String.fromEnvironment(
      'dart.library.typed_data',
    ),
  if (bool.hasEnvironment('dart.library.io'))
    'dart.library.io': String.fromEnvironment('dart.library.io'),
  if (bool.hasEnvironment('dart.library.html'))
    'dart.library.html': String.fromEnvironment('dart.library.html'),
  if (bool.hasEnvironment('dart.library.indexed_db'))
    'dart.library.indexed_db': String.fromEnvironment(
      'dart.library.indexed_db',
    ),
  if (bool.hasEnvironment('dart.library.svg'))
    'dart.library.svg': String.fromEnvironment('dart.library.svg'),
  if (bool.hasEnvironment('dart.library.web_audio'))
    'dart.library.web_audio': String.fromEnvironment('dart.library.web_audio'),
  if (bool.hasEnvironment('dart.library.web_gl'))
    'dart.library.web_gl': String.fromEnvironment('dart.library.web_gl'),
  if (bool.hasEnvironment('dart.library.js_interop'))
    'dart.library.js_interop': String.fromEnvironment(
      'dart.library.js_interop',
    ),
};
