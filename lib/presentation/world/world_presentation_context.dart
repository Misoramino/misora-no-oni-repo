import 'package:flutter/material.dart';

import '../../theme/world_profile.dart';
import 'world_presentation_catalog.dart';
import 'world_presentation_pack.dart';
import 'world_studio_identity.dart';
import 'world_studio_identity_catalog.dart';

/// [ThemeData.extensions] に埋め込んだ世界観。
class WorldProfileTheme extends ThemeExtension<WorldProfileTheme> {
  const WorldProfileTheme(this.profile);

  final WorldProfile profile;

  static WorldProfileTheme? of(BuildContext context) =>
      Theme.of(context).extension<WorldProfileTheme>();

  @override
  WorldProfileTheme copyWith({WorldProfile? profile}) =>
      WorldProfileTheme(profile ?? this.profile);

  @override
  WorldProfileTheme lerp(ThemeExtension<WorldProfileTheme>? other, double t) {
    if (other is! WorldProfileTheme) return this;
    return t < 0.5 ? this : other;
  }
}

extension WorldPresentationContext on BuildContext {
  WorldPresentationPack get worldPresentation {
    final profile =
        WorldProfileTheme.of(this)?.profile ?? WorldProfile.horror;
    return WorldPresentationCatalog.of(profile);
  }

  WorldProfile get worldProfile =>
      WorldProfileTheme.of(this)?.profile ?? WorldProfile.horror;

  WorldStudioIdentity get studioIdentity =>
      WorldStudioIdentityCatalog.of(worldProfile);
}
