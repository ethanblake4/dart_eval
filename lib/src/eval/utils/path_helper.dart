import 'dart:io';
import 'package:path/path.dart' as p;

/// Resolve a path against a given current working directory
String resolvePath(String path, [String? workingDir]) {
  if (path.startsWith('/') || workingDir == null) {
    // Already absolute or no working directory
    return path;
  }
  // Relative path - resolve against workingDir
  return normalizePath('$workingDir/$path');
}

/// Normalize a path by resolving . and .. components
String normalizePath(String path) {
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  final normalizedParts = <String>[];

  for (final part in parts) {
    if (part == '.') {
      // Skip current directory references
      continue;
    } else if (part == '..') {
      // Go up one directory if possible
      if (normalizedParts.isNotEmpty) {
        normalizedParts.removeLast();
      }
    } else {
      normalizedParts.add(part);
    }
  }

  return '/${normalizedParts.join('/')}';
}

/// Recursively resolve symlinks by walking up the directory hierarchy
String resolvePathRecursively(String path) {
  try {
    // Try to resolve the full path directly first
    if (File(path).existsSync()) {
      return File(path).resolveSymbolicLinksSync();
    } else if (Directory(path).existsSync()) {
      return Directory(path).resolveSymbolicLinksSync();
    }

    // If the path doesn't exist, find the deepest existing parent and resolve it
    String current = path;
    List<String> nonExistentParts = [];

    while (current != p.dirname(current)) {
      // While not at root
      // Add the current basename to non-existent parts FIRST
      nonExistentParts.add(p.basename(current));

      String parent = p.dirname(current);

      if (Directory(parent).existsSync()) {
        // Found an existing parent, resolve it and rebuild the path
        String resolvedParent = Directory(parent).resolveSymbolicLinksSync();

        // Rebuild the path with resolved parent + non-existent parts (in reverse order)
        String result = resolvedParent;
        for (String part in nonExistentParts.reversed) {
          result = p.join(result, part);
        }

        return result;
      }

      // Move up to parent
      current = parent;
    }

    // If we reach here, no parent could be resolved
    return path;
  } catch (e) {
    // If any resolution fails, return the original path
    return path;
  }
}
