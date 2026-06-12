import '../features/how_to_play/guide_terms.dart';
import 'match_ui_terms.dart';
import 'player_role.dart';
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
  }) =>
      switch (role) {
        PlayerRole.runner => _runnerStart,
        PlayerRole.hunter => _hunterStart,
        PlayerRole.werewolf => _werewolfStart(werewolfFaction),
      };

  static String matchStartStatusLine(PlayerRole role) => switch (role) {
        PlayerRole.runner => '試合開始。鬼から逃げてください。',
        PlayerRole.hunter => '試合開始。手がかりを読んで追ってください。',
        PlayerRole.werewolf => '試合開始。陣営に応じて立ち回ってください。',
      };

  static const _runnerStart = MatchStartBriefing(
    role: PlayerRole.runner,
    tagline: '逃げながら、手がかりから${GuideTerms.realOni}を見抜きます。',
    winLine: '時間切れで生き残るか、告発で鬼を当てれば勝ちです。',
    mustKnow: [
      '相手の位置は基本見えません。',
      '鬼に近づきすぎると危ない（${GuideTerms.panic}は脱落しません）。',
      '3人以上なら、後半に告発で一発勝ちもあります。',
    ],
  );

  static const _hunterStart = MatchStartBriefing(
    role: PlayerRole.hunter,
    tagline: '痕跡と暴露から逃走者を追い、捕獲する${GuideTerms.trueOni}です。',
    winLine: '人側の生存者を0人にすれば勝ちです。',
    mustKnow: [
      '逃走者の位置は常に見えるわけではありません。',
      '${GuideTerms.anonTrace}や${MatchUiTerms.namedReveal}をつなげて追います。',
      '告発施設の近くにいると、その施設での告発を止められます。',
    ],
  );

  static MatchStartBriefing _werewolfStart(FactionSide? faction) {
    return MatchStartBriefing(
      role: PlayerRole.werewolf,
      tagline:
          '${GuideTerms.werewolf}は鬼のように動けますが、${GuideTerms.realOni}ではありません。',
      winLine: '自分以外の生存者で、人と鬼の少ない方の味方です。',
      mustKnow: [
        '鬼化で姿を切り替え（同数なら${GuideTerms.humanFaction}）。',
        '告発の正解は${GuideTerms.realOni}だけ。人狼は告発できません。',
        faction == null
            ? 'いまの陣営は HUD で確認できます。'
            : 'いまの人数比では${faction.label}（HUD・脱落後は固定）。',
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
      '地図の点は手がかり。現在地と決めつけない',
      '鬼の外側の円で${GuideTerms.panic}、内側で止められ、至近で捕獲',
      'スキル（偽位置・捕獲結界など）で時間を稼ぐ',
      '告発は解禁後のみ。失敗すると脱落（${GuideTerms.echoForm}へ）',
    ],
    notes: [
      '脱落後も${GuideTerms.echoForm}として監視ジャック・告発施設の陣取りが可能',
      'アナリストは痕跡の補助、ハッカーは情報屋を精密に読む特化',
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
      '近い円で止め、至近で捕獲',
      '偽情報・体投げ・捕獲結界で読みをずらす（地図は長押し設置、右上×でキャンセル）',
      '告発施設の近くにいると、その施設での告発を阻止',
    ],
    notes: [
      '鬼化中の${GuideTerms.werewolf}とは${GuideTerms.panic}・捕獲が起きない',
      '脱落後は${GuideTerms.vengefulShadow}として妨害行動が可能（既定）',
    ],
  );

  static const _werewolf = RoleBriefing(
    role: PlayerRole.werewolf,
    headline: '${GuideTerms.werewolf} — 姿と陣営を使い分ける',
    factionLine:
        '${GuideTerms.realOni}でも${GuideTerms.runner}でもない。陣営は人数比で決まる',
    goals: [
      '自分の陣営（人 or 鬼の少ない方）の勝利を目指す',
      '告発の正解は${GuideTerms.realOni}だけと覚える',
    ],
    actions: [
      '鬼化で「人の姿」と「鬼化中」を切り替え',
      '鬼化中は追跡・拘束できるが、${GuideTerms.realOni}とは別扱い',
      '同数なら${GuideTerms.humanFaction}。人側＋鬼化は捕獲可、鬼側＋鬼化は拘束のみ',
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
