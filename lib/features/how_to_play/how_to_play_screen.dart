import 'package:flutter/material.dart';

import '../../game/player_role.dart';
import 'widgets/how_to_play_guide_body.dart';

/// 作戦マニュアル専用画面（ボトムシートより読みやすい全画面表示）。
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({
    this.yourRole,
    this.initialSectionId,
    super.key,
  });

  final PlayerRole? yourRole;
  final String? initialSectionId;

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作戦マニュアル'),
      ),
      body: HowToPlayGuideBody(
        scrollController: _scrollController,
        yourRole: widget.yourRole,
        initialSectionId: widget.initialSectionId,
      ),
    );
  }
}

/// 作戦マニュアルを全画面で開く。
void openHowToPlayScreen(
  BuildContext context, {
  PlayerRole? yourRole,
  String? initialSectionId,
}) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => HowToPlayScreen(
        yourRole: yourRole,
        initialSectionId: initialSectionId,
      ),
    ),
  );
}
