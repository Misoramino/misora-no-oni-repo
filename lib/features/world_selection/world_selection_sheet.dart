import 'dart:async';

import 'package:flutter/material.dart';

import '../../audio/world_audio_director.dart';
import '../../audio/world_audio_state.dart';
import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../presentation/world/world_presentation_catalog.dart';
import '../../presentation/world/world_presentation_context.dart';
import '../../presentation/world/world_presentation_pack.dart';
import '../../presentation/world/world_studio_identity.dart';
import '../../presentation/world/world_studio_identity_catalog.dart';
import '../../presentation/world/world_ui_layout.dart';
import '../../presentation/world/world_icon_frame.dart';
import '../../presentation/world/widgets/world_ambient_painter.dart';
import '../../presentation/world/widgets/world_profile_morph_overlay.dart';
import '../../presentation/world/widgets/world_button.dart';
import '../../presentation/world/widgets/world_loading.dart';
import '../../theme/world_profile.dart';

/// 世界観ギャラリー（作品を選ぶ体験）。
Future<WorldProfile?> showWorldSelectionSheet(
  BuildContext context, {
  required WorldProfile current,
}) {
  return Navigator.of(context).push<WorldProfile>(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) =>
          WorldGalleryScreen(current: current),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final studio = WorldStudioIdentityCatalog.of(current);
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: studio.motion.enterCurve,
          ),
          child: child,
        );
      },
    ),
  );
}

class WorldGalleryScreen extends StatefulWidget {
  const WorldGalleryScreen({required this.current, super.key});

  final WorldProfile current;

  @override
  State<WorldGalleryScreen> createState() => _WorldGalleryScreenState();
}

class _WorldGalleryScreenState extends State<WorldGalleryScreen>
    with TickerProviderStateMixin {
  late WorldProfile _preview = widget.current;
  bool _confirmed = false;
  bool _ambientStarted = false;
  late final PageController _page =
      PageController(initialPage: widget.current.index);
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );

  @override
  void initState() {
    super.initState();
    unawaited(
      WorldAudioDirector.instance.enter(
        WorldAudioState.gallery,
        profile: widget.current,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ambientStarted) return;
    _ambientStarted = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _ambient.dispose();
    if (!_confirmed) {
      unawaited(
        WorldAudioDirector.instance.leaveGallery(
          restoreProfile: widget.current,
        ),
      );
    }
    super.dispose();
  }

  WorldStudioIdentity get _studio => WorldStudioIdentityCatalog.of(_preview);
  WorldPresentationPack get _pack => WorldPresentationCatalog.of(_preview);

  void _onPage(int index) {
    final p = WorldProfile.values[index];
    if (p == _preview) return;
    WorldHaptics.selection(p);
    GameAudio.instance.playWorldSfx(SfxId.uiTap, profile: p);
    unawaited(
      WorldAudioDirector.instance.enter(WorldAudioState.gallery, profile: p),
    );
    setState(() => _preview = p);
  }

  Future<void> _previewBgm() async {
    WorldHaptics.confirm(_preview);
    await WorldAudioDirector.instance.previewGalleryBgm(_preview);
  }

  void _previewSe(SfxId id) {
    WorldHaptics.selection(_preview);
    GameAudio.instance.playGalleryPreviewSfx(id, profile: _preview);
  }

  void _confirm() {
    _confirmed = true;
    WorldHaptics.confirm(_preview);
    GameAudio.instance.playSfx(SfxId.uiTap);
    Navigator.of(context).pop(_preview);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [WorldProfileTheme(_preview)],
      ),
      child: Scaffold(
        backgroundColor: _pack.scaffoldBottom,
        body: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: _pack.scaffoldGradient)),
            WorldProfileMorphOverlay(profile: _preview),
            AnimatedBuilder(
              animation: _ambient,
              builder: (context, child) => RepaintBoundary(
                child: CustomPaint(
                  painter: WorldAmbientPainter(
                    pack: _pack,
                    phase: _ambient.value,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: WorldUILayout.screenPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back, color: _pack.accentOnScaffold),
                          tooltip: '戻る',
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'WORLD GALLERY',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: _pack.accentOnScaffold,
                                      letterSpacing:
                                          _pack.headlineLetterSpacing,
                                    ),
                              ),
                              Text(
                                '世界観とサウンドを選ぶ',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: _pack.mutedOnScaffold),
                              ),
                            ],
                          ),
                        ),
                        if (widget.current == _preview)
                          Chip(
                            label: Text(
                              '選択中',
                              style: TextStyle(
                                color: _pack.buttonLabelOnAccent,
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor: _pack.accent.withValues(alpha: 0.85),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    SizedBox(height: WorldUILayout.sectionGap * 0.5),
                    SizedBox(
                      height: size.height * WorldUILayout.galleryHeroHeight,
                      child: PageView.builder(
                        controller: _page,
                        onPageChanged: _onPage,
                        itemCount: WorldProfile.values.length,
                        itemBuilder: (context, index) {
                          final p = WorldProfile.values[index];
                          final pack = WorldPresentationCatalog.of(p);
                          final studio = WorldStudioIdentityCatalog.of(p);
                          return _GalleryHeroCard(
                            profile: p,
                            pack: pack,
                            studio: studio,
                            selected: p == _preview,
                            float: WorldUILayout.cardFloat,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: WorldUILayout.cardGap),
                    Text(
                      _preview.label,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: _pack.accent,
                            fontWeight: _pack.headlineWeight,
                          ),
                    ),
                    SizedBox(height: WorldUILayout.cardGap * 0.5),
                    Text(
                      _studio.galleryBlurb ?? _pack.shortIntro,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _pack.mutedOnScaffold,
                            height: _pack.bodyLineHeight,
                          ),
                    ),
                    SizedBox(height: WorldUILayout.sectionGap),
                    Text(
                      '試聴',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: _pack.accentMuted,
                          ),
                    ),
                    Text(
                      'タップでサウンドを確認',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _pack.mutedOnScaffold,
                          ),
                    ),
                    SizedBox(height: WorldUILayout.cardGap),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: Text(
                            '操作音',
                            style: TextStyle(color: _pack.textOnPanelOverScaffold),
                          ),
                          backgroundColor: _pack.panelOnScaffold,
                          side: BorderSide(color: _pack.panelBorder),
                          onPressed: () => _previewSe(SfxId.uiTap),
                        ),
                        ActionChip(
                          label: Text(
                            '暴露音',
                            style: TextStyle(color: _pack.textOnPanelOverScaffold),
                          ),
                          backgroundColor: _pack.panelOnScaffold,
                          side: BorderSide(color: _pack.panelBorder),
                          onPressed: () => _previewSe(SfxId.reveal),
                        ),
                        ActionChip(
                          label: Text(
                            '捕獲音',
                            style: TextStyle(color: _pack.textOnPanelOverScaffold),
                          ),
                          backgroundColor: _pack.panelOnScaffold,
                          side: BorderSide(color: _pack.panelBorder),
                          onPressed: () => _previewSe(SfxId.capture),
                        ),
                        ActionChip(
                          label: Text(
                            'BGM',
                            style: TextStyle(color: _pack.textOnPanelOverScaffold),
                          ),
                          backgroundColor: _pack.panelOnScaffold,
                          side: BorderSide(color: _pack.panelBorder),
                          onPressed: _previewBgm,
                        ),
                      ],
                    ),
                    const Spacer(),
                    WorldButtonIcon(
                      profile: _preview,
                      icon: Icons.check_rounded,
                      label: _studio.microcopy.gallerySelect,
                      onPressed: _confirm,
                    ),
                    Text(
                      '選んだ世界を試合に適用',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _pack.mutedOnScaffold,
                          ),
                    ),
                    SizedBox(height: WorldUILayout.cardGap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryHeroCard extends StatelessWidget {
  const _GalleryHeroCard({
    required this.profile,
    required this.pack,
    required this.studio,
    required this.selected,
    required this.float,
  });

  final WorldProfile profile;
  final WorldPresentationPack pack;
  final WorldStudioIdentity studio;
  final bool selected;
  final double float;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: studio.motion.dialog,
      curve: studio.motion.emphasisCurve,
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: float + (selected ? 0 : 8),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pack.scaffoldTop.withValues(alpha: 0.95),
            pack.scaffoldBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(pack.hudCornerRadius + 10),
        border: Border.all(
          color: selected ? pack.accent : pack.panelBorder,
          width: selected ? 2.2 : 1,
        ),
        boxShadow: [
          if (float > 0)
            BoxShadow(
              color: pack.accent.withValues(alpha: 0.15),
              blurRadius: float * 2,
              offset: Offset(0, float),
            ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 24,
            child: Center(
              child: WorldIconFrame.of(profile).heroIcon(
                profile: profile,
                icon: pack.profileIcon,
                iconColor: pack.accent,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 24,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pack.decorSymbol,
                  style: TextStyle(
                    fontSize: 28,
                    color: pack.accentMuted.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  pack.tagline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: pack.textOnScaffold.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SizedBox(
              width: 40,
              height: 40,
              child: selected
                  ? WorldLoading(profile: profile, size: 36)
                  : WorldIconFrame.of(profile).wrap(
                      accent: pack.accentMuted,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          pack.profileIcon,
                          size: 22,
                          color: pack.accentMuted,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
