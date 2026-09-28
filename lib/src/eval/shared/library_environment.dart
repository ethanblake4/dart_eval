/// Host SDK library flags, read at compilation time so conditional imports
/// and evaluated environment constructors agree on the selected platform.
const sdkLibraryEnvironment = <String, String>{
  if (bool.hasEnvironment('dart.library.io'))
    'dart.library.io': String.fromEnvironment('dart.library.io'),
  if (bool.hasEnvironment('dart.library.html'))
    'dart.library.html': String.fromEnvironment('dart.library.html'),
  if (bool.hasEnvironment('dart.library.js_interop'))
    'dart.library.js_interop': String.fromEnvironment(
      'dart.library.js_interop',
    ),
};
