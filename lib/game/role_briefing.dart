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

/// 試合開始ポップアップ用の短い説明（役職理解・最低限だけ）。
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

  /// 試合開始直後のポップアップ（短く・やさしい言葉）。
  static MatchStartBriefing matchStartBriefing(
    PlayerRole role, {
    FactionSide? werewolfFaction,
  }) =>
      switch (role) {
        PlayerRole.runner => _runnerStart,
        PlayerRole.hunter => _hunterStart,
        PlayerRole.werewolf => _werewolfStart(werewolfFaction),
      };

  /// 試合開始直後の HUD ステータス行（役職ごと）。
  static String matchStartStatusLine(PlayerRole role) => switch (role) {
        PlayerRole.runner => '試合開始。鬼から逃げてください。',
        PlayerRole.hunter => '試合開始。逃走者を捕らえてください。',
        PlayerRole.werewolf => '試合開始。陣営に応じて姿を使い分けてください。',
      };

  static const _runnerStart = MatchStartBriefing(
    role: PlayerRole.runner,
    tagline: '鬼から逃げながら、手がかりから${GuideTerms.trueOni}を見抜きます。',
    winLine: '制限時間まで生き残れば、${GuideTerms.humanFaction}の勝ちです。',
    mustKnow: [
      '相手のライブ位置は基本見えません。',
      '近づきすぎると拘束・捕獲されます。${GuideTerms.panic}は脱落しません。',
      '3人以上なら、告発施設で${GuideTerms.trueOni}を当てれば一発勝ちもあります。',
    ],
  );

  static const _hunterStart = MatchStartBriefing(
    role: PlayerRole.hunter,
    tagline: '逃走者を追い詰め、捕獲する${GuideTerms.trueOni}です。',
    winLine: '逃走者を捕まえれば、${GuideTerms.oniFaction}の勝ちです。',
    mustKnow: [
      '逃走者のライブ位置は基本見えません。',
      '${GuideTerms.anonTrace}や${MatchUiTerms.namedReveal}を読んで追跡します。',
      '告発施設の近くにいると、その施設での告発を阻止できます。',
    ],
  );

  static MatchStartBriefing _werewolfStart(FactionSide? faction) {
    return MatchStartBriefing(
      role: PlayerRole.werewolf,
      tagline:
          '${GuideTerms.werewolf}は鬼のように動けますが、${GuideTerms.trueOni}ではありません。',
      winLine: '自分以外の生存者で、人と鬼の少ない方の味方です。',
      mustKnow: [
        '鬼化で「人の姿」と「鬼化中の姿」を切り替え（同数なら${GuideTerms.humanFaction}）。',
        '告発の対象は${GuideTerms.trueOni}だけ。${GuideTerms.werewolf}は告発できません。',
        faction == null
            ? 'いまの陣営は HUD で確認できます。'
            : 'いまの人数比では${faction.label}（HUD・脱落後は固定）。',
      ],
    );
  }

  static const _runner = RoleBriefing(
    role: PlayerRole.runner,
    headline: '${GuideTerms.runner} — 痕跡を読んで勝つ',
    factionLine: '所属: ${GuideTerms.humanFaction}（勝利判定は常に人側）',
    goals: [
      '制限時間まで生き残り、${GuideTerms.humanFaction}の勝利を目指す',
      '3人以上の試合では、告発施設で${GuideTerms.trueOni}を当てれば即勝利',
    ],
    actions: [
      '鬼のライブ位置は見えない。${GuideTerms.anonTrace}・監視・${GuideTerms.panic}・情報屋の断片を読んで動く',
      '接触圏に長くいると${MatchUiTerms.restraint}→${MatchUiTerms.capture}。${GuideTerms.panic}は脱落しないが${GuideTerms.anonTrace}が出やすい',
      'スキル（偽位置・捕獲結界など）で時間を稼ぎ、仲間と情報を共有する',
      '告発は解禁後のみ。失敗すると即脱落（${GuideTerms.echoForm}として${GuideTerms.secondGame}へ）',
    ],
    notes: [
      '脱落後も試合は続く。${GuideTerms.echoForm}なら監視ジャックや告発施設の陣取りで仲間を支援できる',
      '特化役: アナリストは${GuideTerms.anonTrace}の読み取り補助、ハッカーは情報屋の精度アップ（座標ピンは出ません）',
    ],
  );

  static const _hunter = RoleBriefing(
    role: PlayerRole.hunter,
    headline: '${GuideTerms.trueOni} — 痕跡を読んで追い詰める',
    factionLine: '所属: ${GuideTerms.oniFaction}（あなたは${GuideTerms.trueOni}）',
    goals: [
      '逃走者を${MatchUiTerms.capture}・脱落させ、${GuideTerms.oniFaction}の勝利を目指す',
      '告発されないよう、${MatchUiTerms.namedReveal}のタイミングを読む',
    ],
    actions: [
      'ライブ位置は共有されない。遅延軌跡・序盤の手がかり・${GuideTerms.panicTrace}・監視カメラで追う',
      '接触圏に留まると相手を${MatchUiTerms.restraint}。至近距離またはBLE接触で${MatchUiTerms.capture}',
      '偽情報・体投げ・捕獲結界スキルで読みをずらし、複数方向から圧をかける',
      '生存中は告発施設付近にいると、その施設での告発を阻止できる',
    ],
    notes: [
      '鬼化中の${GuideTerms.werewolf}とは${GuideTerms.panic}・${MatchUiTerms.capture}が起きない（鬼同士）',
      '脱落した場合、脱落時点の陣営に応じた${GuideTerms.secondGame}（既定では${GuideTerms.vengefulShadow}）へ',
    ],
  );

  static const _werewolf = RoleBriefing(
    role: PlayerRole.werewolf,
    headline: '${GuideTerms.werewolf} — 姿と陣営を使い分ける',
    factionLine:
        '${GuideTerms.werewolf}は${GuideTerms.trueOni}でも${GuideTerms.runner}でもない特殊役職。陣営は人数比で決まり、見た目とは別',
    goals: [
      '自分の陣営（${GuideTerms.humanFaction} or ${GuideTerms.oniFaction}）の勝利を目指す',
      '鬼化で場を乱しつつ、告発の対象は常に${GuideTerms.trueOni}であることを意識する',
    ],
    actions: [
      '鬼化スキルで「人の姿」と「鬼化中の姿」を切り替え（ボタンは現在の姿に応じて「鬼化」「人化」）',
      '鬼化中は鬼のように見えますが、${GuideTerms.trueOni}の通常スキルや告発対象とは別扱いです',
      '自分以外の生存者で、人と鬼の少ない方の陣営（同数なら${GuideTerms.humanFaction}）',
      '${GuideTerms.humanFaction}＋鬼化: 鬼と同様に接近・${MatchUiTerms.capture}可 / ${GuideTerms.oniFaction}＋鬼化: ${GuideTerms.panic}・${MatchUiTerms.restraint}はあるが${MatchUiTerms.capture}不可',
      'min(10分, 試合時間÷3) ごとに強制切替（通知なし）。自発切替の方がCDが短い',
      '告発は不可',
    ],
    notes: [
      '3人戦では${GuideTerms.humanFaction}になりやすく、鬼化で仲間を脅かす混沌役に',
      '5〜6人では${GuideTerms.oniFaction}になりやすく、鬼化しても直接殺せないため${GuideTerms.trueOni}に追わせる攪乱が鍵',
      '6人以上の試合では${GuideTerms.werewolf}が2人いる。陣営は人数比で個別に決まる',
      '脱落時の陣営は固定（${GuideTerms.humanFaction}→${GuideTerms.echoForm}、${GuideTerms.oniFaction}→${GuideTerms.vengefulShadow}）。その後人数が変わっても変わらない',
    ],
  );

  /// 参照用（現行 UI では [guide_sections] が一次ソース）。即勝利・エリア外の誤解を避ける表現。
  static const winConditions = '''
【${GuideTerms.humanFaction}の勝ち】
・制限時間まで人側の生存者が残る
・告発施設で${GuideTerms.trueOni}を当てる（3人以上・標準設定）
・${GuideTerms.trueOni}が全員脱落する（${MatchUiTerms.capture}・エリア外など）

【${GuideTerms.oniFaction}の勝ち】
・逃走者を${MatchUiTerms.capture}し、人側の生存者が0人になる

個人の脱落と陣営勝敗は別です。脱落しても${GuideTerms.secondGame}で試合に関与できます。
''';
}
