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
        '安全地帯 … 未来の安全を買う（一定時間、追跡されにくくなる）。',
        '鬼に近づきすぎると危ない（${GuideTerms.panic}は脱落しません）。',
        '他役職: 鬼は痕跡で追う／人狼は人数で味方が変わる。',
        ?extra,
      ],
    );
  }

  static const _hunterStart = MatchStartBriefing(
    role: PlayerRole.hunter,
    tagline: '痕跡と暴露から読み、作戦を立てて追う${GuideTerms.trueOni}です。',
    winLine: '逃走者を全員捕まえれば勝ちです。',
    mustKnow: [
      '位置は常に見えません。${GuideTerms.anonTrace}・${MatchUiTerms.namedReveal}・カメラをつなげる。',
      'スキル（偽情報・体投げ・捕獲結界）で読みをずらし、要所へ移動。',
      '告発施設の近くにいると、その施設での告発を止められる。',
      '他役職: 逃走者は情報屋・安全地帯・通信障害を使う／人狼は前半協力・後半翻る。',
    ],
  );

  static MatchStartBriefing _werewolfStart(FactionSide? faction) {
    return MatchStartBriefing(
      role: PlayerRole.werewolf,
      tagline:
          '${GuideTerms.werewolf}は人数で味方が決まる二面役。見た目と陣営は別です。',
      winLine: '生存者のうち、人側と鬼側のどちらか少ない方の陣営が味方です。',
      mustKnow: [
        '前半（人が多い）: 鬼と協力し、人を追い込む・撹乱する（鬼化でも人は襲えない）。',
        '後半（人が減る）: 人側と協力し、鬼を追い詰める（鬼化すると捕獲できる）。',
        '「人化」「鬼化」で姿を切り替え。告発はできません。',
        faction == null
            ? 'いまの陣営は HUD で確認できます。'
            : 'いまの人数比では${faction.label}（HUD・脱落後は固定）。',
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
      '安全地帯 … 未来の安全を買う',
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
      '位置は見えない。痕跡・カメラ・${GuideTerms.panic}から追う',
      'スキルで読みをずらし、要所へ移動して作戦を立てる',
      '近い円で止め、至近で捕獲',
      '告発施設の近くで告発を阻止',
    ],
    notes: [
      '鬼化中の${GuideTerms.werewolf}とは${GuideTerms.panic}・捕獲が起きない',
      '脱落後は${GuideTerms.vengefulShadow}として妨害可能（既定）',
    ],
  );

  static const _werewolf = RoleBriefing(
    role: PlayerRole.werewolf,
    headline: '${GuideTerms.werewolf} — 前半協力・後半翻る',
    factionLine:
        '${GuideTerms.realOni}でも${GuideTerms.runner}でもない。陣営は人数比で決まる',
    goals: [
      '自分の陣営（人 or 鬼の少ない方）の勝利を目指す',
      '告発の正解は${GuideTerms.realOni}だけと覚える',
    ],
    actions: [
      '前半: 鬼側の味方として人を追い込む（鬼化でも人は襲えない）',
      '後半: 人側の味方として鬼を追い詰める（鬼化で捕獲可）',
      '「人化」「鬼化」で姿を切り替え',
      '告発はできない',
    ],
    notes: [
      '3人戦は人側寄り、5〜6人は鬼側寄りになりやすい',
      '6人以上で人狼2人のことも。脱落時の陣営は固定',
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
