/// Describes a runtime override stored in the program.
class OverrideSpec {
  /// Creates a new [OverrideSpec].
  const OverrideSpec(this.offset, this.versionConstraint);

  /// The bytecode offset of the override.
  final int offset;

  /// The pub_semver version constraint of the override.
  final String? versionConstraint;
}
