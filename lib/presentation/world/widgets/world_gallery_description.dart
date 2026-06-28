import 'package:flutter/material.dart';

import '../../../theme/world_profile.dart';
import '../world_gallery_copy.dart';
import '../world_presentation_pack.dart';

/// ギャラリー説明文 — 2 行分の高さを確保し、世界切替でレイアウトが動かない。
class WorldGalleryDescription extends StatelessWidget {
  const WorldGalleryDescription({
    required this.profile,
    required this.pack,
    super.key,
  });

  final WorldProfile profile;
  final WorldPresentationPack pack;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    final style = base?.copyWith(
      color: pack.mutedOnScaffold,
      height: pack.bodyLineHeight,
    );
    final fontSize = style?.fontSize ?? 14.0;
    final lineHeight = fontSize * (style?.height ?? 1.45);

    return SizedBox(
      height: lineHeight * 2 + 2,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Text(
          WorldGalleryCopy.description(profile),
          key: ValueKey(profile),
          textAlign: TextAlign.center,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.clip,
        ),
      ),
    );
  }
}
