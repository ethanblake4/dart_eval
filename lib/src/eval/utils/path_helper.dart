import 'dart:io';
import 'package:path/path.dart' as p;

/// Check if a given path is allowed by this permission
bool isPathAllowed(String targetPath, String allowedPath) {
  // Empty allowedPath means allow everything (any permission)
  if (allowedPath.isEmpty) return true;

  // Normalize both paths using the same resolution method
  String normalizedTarget = normalizePath(targetPath);
  String normalizedAllowed = allowedPath;

  // Both paths should now be consistently resolved (with symlinks resolved when possible)

  // Ensure both paths end consistently for directory checks
  // If allowed path is a directory, ensure it ends with separator for proper containment check
  if (normalizedAllowed.isNotEmpty &&
      !normalizedAllowed.endsWith(p.separator)) {
    // Check if it's a directory or if we should treat it as one
    bool isDirectory = false;
    try {
      isDirectory = Directory(normalizedAllowed).existsSync();
    } catch (e) {
      // Ignore exceptions and fall through to heuristic check
    }

    // If directory doesn't exist, use heuristic: assume it's a directory if basename has no extension
    if (!isDirectory && !p.basename(normalizedAllowed).contains('.')) {
      isDirectory = true;
    }

    if (isDirectory) {
      normalizedAllowed = normalizedAllowed + p.separator;
    }
  }

  // Check if target is the same as or within allowed path
  if (normalizedTarget ==
      normalizedAllowed.replaceAll(RegExp(r'[/\\]+$'), '')) {
    return true; // Exact match
  }

  // Check if target is within allowed directory
  if (normalizedAllowed.endsWith(p.separator)) {
    return normalizedTarget.startsWith(normalizedAllowed);
  }

  // For file permissions, check exact match
  return normalizedTarget == normalizedAllowed;
}

/// Normalize a path by resolving symlinks and ensuring consistent separators
String normalizePath(String path) {
  if (path.isEmpty) return '';

  // Convert to absolute path and normalize
  String absolutePath = p.isAbsolute(path) ? path : p.absolute(path);

  // Normalize to resolve .. and . components and remove redundant separators
  String normalized = p.normalize(absolutePath);

  // Try to resolve symlinks by walking up the directory tree
  String resolved = resolvePathRecursively(normalized);

  return resolved;
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
