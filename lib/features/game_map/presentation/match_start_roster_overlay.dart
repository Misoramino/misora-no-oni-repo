import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../game/player_role.dart';
import '../../../session/avatar_thumb_codec.dart';
import '../../../theme/world_launch_branding.dart';
import '../../../theme/world_profile.dart';

/// 試合開始前の参加者ロスター表示用。
class MatchStartRosterEntry {
  const MatchStartRosterEntry({
    required this.label,
    required this.role,
    this.avatarThumbB64,
    this.avatarImagePath,
    this.isSelf = false,
  });

  final String label;
  final PlayerRole role;
  final String? avatarThumbB64;
  final String? avatarImagePath;
  final bool isSelf;
}

Future<void> showMatchStartRoster({
  required BuildContext context,
  required WorldProfile profile,
  required List<MatchStartRosterEntry> entries,
}) async {
  if (!context.mounted || entries.isEmpty) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => _MatchStartRosterOverlay(
      profile: profile,
      entries: entries,
    ),
  );
}

class _MatchStartRosterOverlay extends StatefulWidget {
  const _MatchStartRosterOverlay({
    required this.profile,
    required this.entries,
  });

  final WorldProfile profile;
  final List<MatchStartRosterEntry> entries;

  @override
  State<_MatchStartRosterOverlay> createState() =>
      _MatchStartRosterOverlayState();
}

class _MatchStartRosterOverlayState extends State<_MatchStartRosterOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _autoClose;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  WorldLaunchBranding get _branding => WorldLaunchBranding.of(widget.profile);

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
    _autoClose = Timer(const Duration(milliseconds: 2800), _close);
  }

  void _close() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _branding.accent;
    final count = widget.entries.length;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                '参加者',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accent.withValues(alpha: 0.85),
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count 人が参加',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _RosterBody(
                      entries: widget.entries,
                      accent: accent,
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _close,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: const Text('スキップ'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RosterBody extends StatelessWidget {
  const _RosterBody({
    required this.entries,
    required this.accent,
    required this.maxWidth,
    required this.maxHeight,
  });

  final List<MatchStartRosterEntry> entries;
  final Color accent;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final n = entries.length;
    if (n <= 2) {
      return _verticalList(context, large: true);
    }
    if (n <= 4 || maxWidth < 360) {
      return _twoColumnGrid(context);
    }
    if (n <= 6 && maxHeight > 420) {
      return _staggeredPairs(context);
    }
    return _adaptiveGrid(context);
  }

  Widget _verticalList(BuildContext context, {required bool large}) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _RosterTile(
        entry: entries[i],
        accent: accent,
        avatarSize: large ? 64 : 52,
        compact: false,
      ),
    );
  }

  Widget _twoColumnGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) => _RosterTile(
        entry: entries[i],
        accent: accent,
        avatarSize: 52,
        compact: true,
      ),
    );
  }

  Widget _staggeredPairs(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (var i = 0; i < entries.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: _RosterTile(
                    entry: entries[i],
                    accent: accent,
                    avatarSize: 48,
                    compact: true,
                  ),
                ),
                if (i + 1 < entries.length) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RosterTile(
                      entry: entries[i + 1],
                      accent: accent,
                      avatarSize: 48,
                      compact: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _adaptiveGrid(BuildContext context) {
    final cols = maxWidth >= 520 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: cols == 3 ? 0.92 : 1.0,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) => _RosterTile(
        entry: entries[i],
        accent: accent,
        avatarSize: 44,
        compact: true,
      ),
    );
  }
}

class _RosterTile extends StatelessWidget {
  const _RosterTile({
    required this.entry,
    required this.accent,
    required this.avatarSize,
    required this.compact,
  });

  final MatchStartRosterEntry entry;
  final Color accent;
  final double avatarSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = switch (entry.role) {
      PlayerRole.hunter => const Color(0xFFE53935),
      PlayerRole.werewolf => const Color(0xFF7E57C2),
      PlayerRole.runner => const Color(0xFF43A047),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isSelf
              ? accent.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.12),
          width: entry.isSelf ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: compact ? 10 : 14,
        ),
        child: compact
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AvatarCircle(
                    bytes: AvatarThumbCodec.decode(entry.avatarThumbB64),
                    imagePath: entry.avatarImagePath,
                    size: avatarSize,
                    accent: accent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _RoleChip(label: entry.role.displayName, color: roleColor),
                ],
              )
            : Row(
                children: [
                  _AvatarCircle(
                    bytes: AvatarThumbCodec.decode(entry.avatarThumbB64),
                    imagePath: entry.avatarImagePath,
                    size: avatarSize,
                    accent: accent,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _RoleChip(
                          label: entry.role.displayName,
                          color: roleColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.bytes,
    required this.imagePath,
    required this.size,
    required this.accent,
  });

  final Uint8List? bytes;
  final String? imagePath;
  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final file = imagePath != null && imagePath!.isNotEmpty
        ? File(imagePath!)
        : null;
    final hasFile = file != null && file.existsSync();
    final hasBytes = bytes != null && bytes!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
        color: Colors.white.withValues(alpha: 0.08),
        image: hasBytes
            ? DecorationImage(
                image: MemoryImage(bytes!),
                fit: BoxFit.cover,
              )
            : hasFile
                ? DecorationImage(
                    image: FileImage(file),
                    fit: BoxFit.cover,
                  )
                : null,
      ),
      child: !hasBytes && !hasFile
          ? Icon(
              Icons.person_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: size * 0.48,
            )
          : null,
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
