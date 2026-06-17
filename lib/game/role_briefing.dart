import '../features/how_to_play/guide_terms.dart';
import 'match_ui_terms.dart';
import 'player_role.dart';
import 'runner_modifier.dart';
import 'werewolf_faction_logic.dart';

/// 役職ごとの詳細説明（遊び方シート用）。
class RoleBriefing {
  const RoleBriefing({
    required this.role,
    required this.headline,
    required this.factionLine,
    required this.goals,
    required this.actions,
    this.notes = const [],
  });

  final PlayerRole role;
  final String headline;
  final String factionLine;
  final List<String> goals;
  final List<String> actions;
  final List<String> notes;
}

/// 試合開始ポップアップ用の短い説明。
class MatchStartBriefing {
  const MatchStartBriefing({
    required this.role,
    required this.tagline,
    required this.winLine,
    required this.mustKnow,
    this.learnMoreHint = MatchUiTerms.learnMoreHint,
  });

  final PlayerRole role;
  final String tagline;
  final String winLine;
  final List<String> mustKnow;
  final String learnMoreHint;
}

abstract final class RoleBriefingCatalog {
  static RoleBriefing forRole(PlayerRole role) => switch (role) {
        PlayerRole.runner => _runner,
        PlayerRole.hunter => _hunter,
        PlayerRole.werewolf => _werewolf,
      };

  static MatchStartBriefing matchStartBriefing(
    PlayerRole role, {
    FactionSide? werewolfFaction,
    RunnerModifier runnerModifier = RunnerModifier.none,
  }) =>
      switch (role) {
        PlayerRole.runner => _runnerStart(runnerModifier),
        PlayerRole.hunter => _hunterStart,
        PlayerRole.werewolf => _werewolfStart(werewolfFaction),
      };

  static String matchStartStatusLine(PlayerRole role) => switch (role) {
        PlayerRole.runner => '試合開始。鬼から逃げてください。',
        PlayerRole.hunter => '試合開始。手がかりを読んで追ってください。',
        PlayerRole.werewolf => '試合開始。陣営に応じて立ち回ってください。',
      };

  static MatchStartBriefing _runnerStart(RunnerModifier modifier) {
    final extra = switch (modifier) {
      RunnerModifier.analyst => '特化: ${modifier.label} — ${GuideTerms.anonTrace}の観測源・位置誤差が読めます。',
      RunnerModifier.hacker =>
        '特化: ${modifier.label} — 情報屋の距離が精密になり、鬼の向きが分かることがあります（座標ピンは出ません）。',
      RunnerModifier.none => null,
    };
    return MatchStartBriefing(
      role: PlayerRole.runner,
      tagline: '逃げながら、地図のギミックと手がかりで${GuideTerms.realOni}を見抜きます。',
      winLine: '時間切れで生き残るか、告発で鬼を当てれば勝ちです。',
      mustKnow: [
        '情報屋 … 鬼の方角・距離の手がかり（今どこにいるかの答えではない）。',
        '通信障害地帯 … 今の安全度を上げやすい（暴露位置がノイズになりやすい）。',
        '安全地帯 … チャージで追跡されにくくなる（使うと別の場所へ移動）。',
        '鬼に近づきすぎると危ない（${GuideTerms.panic}は脱落しません）。',
        '他役職: 鬼は痕跡で追う／人狼は人数で味方が変わる。',
        ?extra,
      ],
    );
  }

  static const _hunterStart = MatchStartBriefing(
    role: PlayerRole.hunter,
    tagline: 'あなたは${GuideTerms.trueOni}。逃走者の「いまここ」は見えません。',
    winLine: '逃走者を全員捕獲すれば勝ちです。',
    mustKnow: [
      '見えるのは痕跡（?）・名前付き暴露・カメラだけ。',
      '点をつないで、どこへ逃げたかを読みます。',
      '至近まで近づくと捕獲。結界や体投げで追い詰められます。',
      '告発施設のそばにいると、味方の告発を止められます。',
    ],
  );

  static MatchStartBriefing _werewolfStart(FactionSide? faction) {
    final factionLine = switch (faction) {
      FactionSide.humanTeam =>
        'いまは${GuideTerms.humanFaction}。鬼化すると逃走者を捕獲できます。',
      FactionSide.oniTeam =>
        'いまは${GuideTerms.oniFaction}。鬼化は追跡・拘束向き（捕獲は不可）。',
      null =>
        '人数比で陣営が決まります（3人戦は人側・5〜6人は鬼側になりやすい）。',
    };
    return MatchStartBriefing(
      role: PlayerRole.werewolf,
      tagline:
          '${GuideTerms.werewolf}は人数で味方が決まる二面役。見た目と陣営は別です。',
      winLine: '人数が少ない方の陣営が味方。そちらが勝てばあなたの勝ちです。',
      mustKnow: [
        factionLine,
        '「人化」「鬼化」で姿を切り替え。HUDに「強制まで」と「切替CD」が別表示。',
        '強制切替直後は切替CDがやや長くなります。告発はできません。',
        faction == null
            ? 'いまの陣営は HUD で確認できます。'
            : '脱落後の第二ゲームもこの陣営で固定です。',
        '他役職: 鬼は手がかりで追う／逃走者はギミック3択で生き延びる。',
      ],
    );
  }

  static const _runner = RoleBriefing(
    role: PlayerRole.runner,
    headline: '${GuideTerms.runner} — 逃げて、読んで、当てる',
    factionLine: '${GuideTerms.humanFaction}。勝利判定は常に人側です。',
    goals: [
      '時間切れまで生き残る',
      '告発で${GuideTerms.realOni}を当てる（3人以上・標準設定）',
    ],
    actions: [
      '情報屋 … 鬼の方角・距離（座標そのものではない）',
      '通信障害地帯 … 今の安全度を上げる',
      '安全地帯 … チャージで追跡されにくくなる（移動あり）',
      '告発は解禁後のみ。失敗すると脱落（${GuideTerms.echoForm}へ）',
    ],
    notes: [
      'アナリスト: ${GuideTerms.anonTrace}の観測源・位置誤差を読む',
      'ハッカー: 情報屋を精密化＋鬼の向き（座標ピンは出ない）',
    ],
  );

  static const _hunter = RoleBriefing(
    role: PlayerRole.hunter,
    headline: '${GuideTerms.trueOni} — 手がかりで追う',
    factionLine: '${GuideTerms.oniFaction}。あなたは${GuideTerms.realOni}です。',
    goals: [
      '逃走者を捕獲し、人側の生存者を0人にする',
      '告発される前に決着をつける',
    ],
    actions: [
      '今いる場所は見えない。痕跡・カメラ・${GuideTerms.panic}から追う',
      'スキルで読みをずらし、要所へ移動して作戦を立てる',
      '近い円で止め、至近で捕獲',
      '告発施設の近くで告発を阻止',
    ],
    notes: [
      '人陣営＋鬼化の人狼は通常どおり追跡・捕獲可能',
      '鬼陣営＋鬼化の人狼とは本鬼同士と同様、互いにパニック・捕獲しない',
      '脱落後は${GuideTerms.vengefulShadow}として妨害可能（既定）',
    ],
  );

  static const _werewolf = RoleBriefing(
    role: PlayerRole.werewolf,
    headline: '${GuideTerms.werewolf} — 陣営に応じて立ち回る',
    factionLine:
        '${GuideTerms.realOni}でも${GuideTerms.runner}でもない。陣営は人数比で決まる',
    goals: [
      '自分の陣営（人 or 鬼の少ない方）の勝利を目指す',
      '告発の正解は${GuideTerms.realOni}だけと覚える',
    ],
    actions: [
      '${GuideTerms.humanFaction}: 鬼化で逃走者を捕獲できる',
      '${GuideTerms.oniFaction}: 鬼化は追跡・拘束向き（捕獲不可・攪乱）',
      '「人化」「鬼化」で姿を切り替え（強制まで／切替CDは別表示）',
      '告発はできない',
    ],
    notes: [
      '3人戦は人側寄り、5〜6人は鬼側寄りになりやすい',
      '脱落時の陣営は固定（途中で人数が変わっても切り替わらない）',
      '6人以上で人狼2人のことも',
    ],
  );

  static const winConditions = '''
【${GuideTerms.humanFaction}の勝ち】
・制限時間まで生存者が残る
・告発で${GuideTerms.realOni}を当てる（3人以上・標準設定）
・${GuideTerms.realOni}が全員脱落

【${GuideTerms.oniFaction}の勝ち】
・人側の生存者を0人にする

脱落しても${GuideTerms.secondGame}で試合に関われます。
''';
}
