import '../game_random.dart';

/// Explicit Minecraft version value type used at the engine query boundary.
///
/// Where the legacy search path uses the coarse [VersionEra] (`legacy`/
/// `modern`), the seed-accurate engine needs to distinguish individual
/// versions (e.g. Java 1.18 vs 1.20) because placement tables, salts, and
/// RNG parameters differ between them. A [MinecraftVersion] is identified by a
/// stable string [id] such as `"java-1.20"` or `"bedrock-1.21"`.
///
/// Kept pure Dart (no Flutter imports) so it can travel across the `compute`
/// isolate boundary and be unit-tested in isolation, matching the existing
/// [VersionAvailability] convention.
class MinecraftVersion {
  /// Stable identifier, e.g. `"java-1.20"`. Lower-case, `<edition>-<version>`.
  final String id;

  const MinecraftVersion(this.id);

  /// Convenience constructor building the canonical id from an [edition] and a
  /// release string like `"1.20"`.
  factory MinecraftVersion.of(MinecraftEdition edition, String release) {
    return MinecraftVersion('${_editionSlug(edition)}-$release');
  }

  static String _editionSlug(MinecraftEdition edition) {
    switch (edition) {
      case MinecraftEdition.java:
        return 'java';
      case MinecraftEdition.bedrock:
        return 'bedrock';
    }
  }

  /// The edition implied by this version's [id] prefix. Defaults to
  /// [MinecraftEdition.java] when the prefix is not recognised.
  MinecraftEdition get edition {
    if (id.startsWith('bedrock-')) return MinecraftEdition.bedrock;
    return MinecraftEdition.java;
  }

  /// The release portion of the id (everything after the first `-`), e.g.
  /// `"1.20"` for `"java-1.20"`. Returns the whole id when there is no `-`.
  String get release {
    final int dash = id.indexOf('-');
    if (dash < 0 || dash + 1 >= id.length) return id;
    return id.substring(dash + 1);
  }

  /// Maps this explicit version down to the legacy [VersionEra] bucket the
  /// existing finders (and the Simulated engine path) understand.
  ///
  /// The app's "legacy" bucket collapses every pre-1.18 release; anything 1.18
  /// or newer is "modern". We parse the leading `major.minor` from [release]
  /// and treat `>= 1.18` as modern. Unparseable releases default to modern
  /// (the richer, less restrictive bucket).
  VersionEra get era {
    final parts = release.split('.');
    if (parts.length >= 2) {
      final major = int.tryParse(parts[0]);
      final minor = int.tryParse(parts[1]);
      if (major != null && minor != null) {
        if (major < 1) return VersionEra.legacy;
        if (major == 1 && minor < 18) return VersionEra.legacy;
      }
    }
    return VersionEra.modern;
  }

  @override
  bool operator ==(Object other) =>
      other is MinecraftVersion && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MinecraftVersion($id)';
}
