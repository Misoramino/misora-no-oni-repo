# 08_Implementation.md

> この文書は「ONI PIN HowToPlay Ver2」設計書の一部です。
> 実装前に `00_MasterIndex.md` から順番に、同フォルダ内の全ファイルを読んでください。
> 途中のファイルだけを読んで実装しないでください。

# ONI PIN HowToPlay Ver2 Implementation Guide

## 1. このファイルの目的

このファイルは、CursorがONI PINの遊び方・チュートリアル・図解・文言を実装するための具体的な実装指示である。

この実装では、ゲームロジックを変更しない。

対象は以下。

* 遊び方ガイドのUI再構成
* ガイド本文の差し替え
* 図解カードの追加
* 詳細折りたたみの追加
* チュートリアル文言・導線の改善
* HUDや通知文言の用語統一
* 関連ガイドリンクの追加

---

# 2. 最初に読むファイル

実装前に、必ず以下を順番に読むこと。

```text
docs/how_to_play_v2/00_MasterIndex.md
docs/how_to_play_v2/01_Project.md
docs/how_to_play_v2/02_InformationArchitecture.md
docs/how_to_play_v2/03_UI_Layout.md
docs/how_to_play_v2/04_GuideBook.md
docs/how_to_play_v2/05_Tutorial.md
docs/how_to_play_v2/06_Diagrams.md
docs/how_to_play_v2/07_CopyWriting.md
docs/how_to_play_v2/08_Implementation.md
```

途中のファイルだけ読んで実装しないこと。

---

# 3. 実装前に確認する既存ファイル

以下の既存ファイルを確認すること。

```text
lib/features/how_to_play/guide_sections.dart（旧 how_to_play_content.dart は統合済み）
lib/game/game_config.dart
lib/game/match_duration_scaling.dart
lib/features/game_map/match/
lib/game/werewolf_faction_logic.dart
lib/game/werewolf_forced_schedule.dart
lib/game/accusation_logic.dart
lib/game/accusation_sites.dart
lib/screens/game_map_screen.second_game.dart
lib/screens/game_map_screen.match_lifecycle.dart
```

既存構成に合わせて実装すること。

ファイル名は現行プロジェクト構造に合わせて調整してよい。

---

# 4. 実装で変更してよい範囲

変更してよいもの:

* 遊び方UI
* 表示文
* 見出し
* アイコン
* カード構成
* 折りたたみ
* 図解Widget
* ガイドデータ構造
* チュートリアル文言
* チュートリアル終了後の導線
* HUD通知の文言
* 用語定数

---

# 5. 実装で変更してはいけない範囲

変更してはいけないもの:

* 勝敗判定
* 捕獲判定
* パニック判定
* エリア外判定
* 告発ロジック
* 役職配分
* 人狼陣営判定
* 第二ゲーム効果
* スキル性能
* 秒数
* 距離
* クールダウン
* Firestore同期仕様
* ギャラリー保存仕様

この実装はUX・UI・文言の改善であり、ゲームバランス変更ではない。

---

# 6. 推奨実装順

## Phase 1: 現状把握

1. 既存の `how_to_play_content.dart` を読む
2. 既存のチュートリアル導線を確認する
3. 既存の文言定数があるか確認する
4. `MatchUiTerms` のような用語管理がある場合は確認する

## Phase 2: ガイドUIの土台を作る

以下のWidgetまたは同等の構造を作る。

```text
HowToPlayGuideScreen
GuideHeaderCard
GuideSectionIndex
GuideSection
GuideCard
GuideDiagramCard
GuideDetailExpansion
RelatedGuideLinks
SpecTable
```

既存Widgetに統合できるなら、新規Screen名にこだわらなくてよい。

## Phase 3: ガイドデータを作る

`04_GuideBook.md` の本文を元に、セクションデータを作る。

おすすめはデータ駆動。

例:

```dart
final howToPlaySections = <GuideSectionData>[
  GuideSectionData(
    id: 'intro',
    title: 'はじめに',
    oneLine: 'ONI PINは、位置を読む情報戦です。',
    cards: [...],
  ),
];
```

## Phase 4: 図解カードを追加する

`06_Diagrams.md` の優先順位に従う。

最初に実装する図:

1. 名前付き暴露と匿名痕跡
2. 鬼との距離と危険度
3. エリア外の危険段階
4. 告発の流れ
5. 脱落後の分岐

## Phase 5: 詳細折りたたみを追加する

秒数・距離・CDなどを折りたたみに入れる。

トップレベルに大量の数値を出さない。

## Phase 6: チュートリアル文言を改善する

`05_Tutorial.md` と `07_CopyWriting.md` に従って、役職別チュートリアル文言を調整する。

## Phase 7: 通知文言を統一する

HUD・ログ・通知の文言を `07_CopyWriting.md` に合わせる。

ただし、ロジックは変更しない。

## Phase 8: 動作確認

実装後、以下を確認する。

* ガイドが開ける
* 各章が見やすい
* 折りたたみが動く
* 図解が崩れない
* 小さい画面で読める
* 既存の試合進行が壊れていない

---

# 7. 推奨データ構造

## GuideSectionData

```dart
class GuideSectionData {
  const GuideSectionData({
    required this.id,
    required this.title,
    required this.icon,
    required this.oneLine,
    required this.cards,
    this.details = const [],
    this.relatedSectionIds = const [],
  });

  final String id;
  final String title;
  final IconData icon;
  final String oneLine;
  final List<GuideCardData> cards;
  final List<GuideDetailData> details;
  final List<String> relatedSectionIds;
}
```

## GuideCardData

```dart
class GuideCardData {
  const GuideCardData({
    required this.id,
    required this.title,
    required this.icon,
    required this.oneLine,
    required this.body,
    this.bullets = const [],
    this.diagram,
    this.details = const [],
  });

  final String id;
  final String title;
  final IconData icon;
  final String oneLine;
  final String body;
  final List<String> bullets;
  final GuideDiagramData? diagram;
  final List<GuideDetailData> details;
}
```

## GuideDetailData

```dart
class GuideDetailData {
  const GuideDetailData({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
```

## GuideDiagramData

```dart
class GuideDiagramData {
  const GuideDiagramData({
    required this.type,
    required this.title,
    required this.caption,
  });

  final GuideDiagramType type;
  final String title;
  final String caption;
}
```

## GuideDiagramType

```dart
enum GuideDiagramType {
  informationTypes,
  combatDanger,
  outsideAreaFlow,
  accusationFlow,
  secondGameBranch,
  facilityRoles,
  werewolfNotOni,
  skillPlacement,
}
```

この構造は提案である。

既存構成に合わない場合は、同等の保守性を持つ構造に調整してよい。

---

# 8. 推奨Widget構造

## HowToPlayGuideScreen

役割:

* 全体Scaffold
* AppBar
* ListView
* Header
* SectionIndex
* Section一覧

## GuideHeaderCard

表示内容:

```text
ONI PIN 作戦マニュアル
位置は見えない。痕跡を読み、鬼を出し抜け。
```

本文:

```text
全部を最初から読む必要はありません。
試合中に困ったら、必要な章だけ開いてください。
```

## GuideSectionIndex

役割:

* セクション一覧を表示
* タップで該当セクションへスクロール
* 実装が大変なら、まずは単なる一覧でよい

## GuideSection

役割:

* 章のまとまり
* 見出し
* 一言説明
* カード一覧
* 詳細
* 関連リンク

## GuideCard

役割:

* 1テーマの説明
* 1カードに1概念
* 長くしすぎない

## GuideDetailExpansion

役割:

* 詳細仕様を折りたたむ
* 初期状態は閉じる

## RelatedGuideLinks

役割:

* 関連章へ移動
* 実装が大変なら、まずは表示だけでもよい

---

# 9. レスポンシブ対応

主な利用はスマホ縦画面を想定する。

## 小さい画面

* 2カラムを避ける
* 比較カードは縦積みにする
* 図解は横幅に合わせる
* 長い表はカード化する

## 大きい画面

* セクション一覧をグリッド表示してよい
* 比較カードを左右2カラムにしてよい

---

# 10. 実装する本文

本文は `04_GuideBook.md` を基準にする。

ただし、アプリUIに入れる際に、次の調整はしてよい。

* 長すぎる本文を複数カードに分割する
* 箇条書きにする
* 同じ意味の文章を短くする
* 詳細へ移す
* 既存UIに合わせて語尾を微調整する

禁止:

* 重要仕様を消す
* 意味を変える
* 人狼を本鬼扱いする
* 鬼エリア外を即人勝利扱いする
* 匿名痕跡を名前付き扱いする
* パニックを脱落扱いする

---

# 11. 図解の実装

## 初期実装

図解は最初から高度なグラフィックでなくてよい。

以下で実装してよい。

* Icon
* Text
* Container
* Row
* Column
* Divider
* Card
* Flow風の矢印

## 将来置き換え

将来的に以下へ置き換えてよい。

* CustomPainter
* SVG
* Lottie
* Map風の簡易図
* アニメーション

ただし、図解の意味は `06_Diagrams.md` から変えない。

---

# 12. チュートリアル実装

既存チュートリアルがある場合、それを壊さず文言と流れを調整する。

## 役職別

* 逃走者
* 本鬼
* 人狼
* 残響体
* 復讐の鬼影

最低限、最初は以下を実装する。

* 逃走者
* 本鬼
* 人狼

第二ゲーム系は後続でもよい。

## チュートリアル終了後

関連ガイドへの導線を追加する。

例:

```text
関連ガイドを見る
```

タップで該当章へ遷移、または作戦マニュアルを開く。

---

# 13. 通知文言の実装

`07_CopyWriting.md` の文言に合わせる。

既存の通知システムがある場合は、文言だけ差し替える。

内部キーやイベント名は変更しない。

## 優先して差し替える文言

* パニック
* 匿名痕跡
* 名前付き暴露
* 接触拘束
* 捕獲
* エリア外
* 告発
* 第二ゲーム
* 人狼

---

# 14. 用語定数化

同じ用語を複数箇所に直書きしない。

推奨:

```dart
class OniPinTerms {
  static const panic = 'パニック';
  static const anonymousTrace = '匿名痕跡';
  static const identifiedReveal = '名前付き暴露';
  static const trueOni = '本鬼';
  static const werewolf = '人狼';
  static const echoBody = '残響体';
  static const revengeShadow = '復讐の鬼影';
}
```

既に既存の用語クラスがある場合は、それを拡張する。

---

# 15. テスト・確認項目

## 表示確認

* 作戦マニュアルが開ける
* すべてのセクションが表示される
* 折りたたみが開閉できる
* 図解が小さい画面で崩れない
* 長文が画面外にはみ出さない
* ダークモードで読める
* 既存テーマと合っている

## 内容確認

* 「感染」と表示されていない
* ライブ位置が見えるゲームだと誤解されない
* 名前付き暴露と匿名痕跡が区別されている
* パニックが脱落ではないと分かる
* 拘束と捕獲が区別されている
* エリア外が即脱落ではないと分かる
* 鬼もエリア外で脱落すると分かる
* 人狼が本鬼ではないと分かる
* 告発できるのは生存中の逃走者だと分かる
* 本鬼が施設付近にいると告発不可だと分かる
* 脱落後も第二ゲームがあると分かる

## ロジック確認

* 試合開始が壊れていない
* 役職配布が壊れていない
* スキル発動が壊れていない
* エリア外判定が壊れていない
* 捕獲判定が壊れていない
* 告発判定が壊れていない
* 第二ゲームが壊れていない
* オンライン同期が壊れていない

---

# 16. 実装時の注意点

## 16.1 長文Textを避ける

大きな説明文を1つのTextにまとめない。

必ずカード分割する。

## 16.2 詳細を初期表示しない

詳細仕様は折りたたみにする。

## 16.3 用語を揺らさない

同じ概念に複数の名称を使わない。

例:

```text
匿名痕跡
匿名位置
名前なし暴露
```

のように揺らさない。

基本は「匿名痕跡」に統一。

## 16.4 現在地と断定しない

暴露や痕跡の説明で、

```text
ここにいます
```

と書かない。

```text
ここで暴露されました
この付近にいた手がかりです
```

と書く。

## 16.5 パニックを負け扱いしない

パニックは脱落ではない。

表示上も、赤一色でゲームオーバーのように見せない。

## 16.6 人狼を鬼と混同させない

人狼は鬼化できるが、本鬼ではない。

図解・役職説明・告発説明で必ず区別する。

---

# 17. ファイル構成案

新規または整理後の構成案。

```text
lib/features/game_map/widgets/how_to_play/
├── how_to_play_guide_screen.dart
├── guide_section_data.dart
├── guide_sections.dart
├── guide_header_card.dart
├── guide_section_index.dart
├── guide_section_widget.dart
├── guide_card.dart
├── guide_diagram_card.dart
├── guide_detail_expansion.dart
├── related_guide_links.dart
└── spec_table.dart
```

既存構成に合わせる場合は、この通りでなくてもよい。

ただし、巨大な1ファイルにしないこと。

---

# 18. 最小実装案

時間がない場合の最小実装。

1. 既存 `how_to_play_content.dart` をカード型に整理
2. `04_GuideBook.md` の本文を反映
3. 詳細仕様を `ExpansionTile` に入れる
4. 主要5図だけ簡易Widgetで実装
5. パニック・匿名痕跡・名前付き暴露・人狼の文言を統一

最小実装でも、以下は必須。

* 情報戦ページ
* 鬼との戦いページ
* エリア外ページ
* 告発ページ
* 第二ゲームページ
* 詳細ルールページ

---

# 19. フル実装案

余裕がある場合のフル実装。

* セクション一覧からスクロールジャンプ
* 関連ガイドリンク
* チュートリアル終了後の関連ガイド誘導
* 図解Widgetの共通化
* 用語定数化
* HUD通知の文言統一
* 役職開示文の改善
* 第二ゲームチュートリアル
* ダークモード最適化
* 将来SVG差し替え可能なDiagramType設計

---

# 20. Cursorへの最終指示文

実装を開始するとき、ユーザーはCursorに以下のように指示するとよい。

```text
docs/how_to_play_v2/ 配下の設計書を 00_MasterIndex.md から順番にすべて読んでください。

これはONI PINの遊び方・チュートリアル・図解・文言を改善するためのUX設計書です。

ゲームロジック、勝敗条件、秒数、距離、スキル性能、告発条件、人狼判定、第二ゲーム効果は変更しないでください。

まず既存の how_to_play_content.dart と関連するチュートリアル・文言定数を確認し、設計書に従って、作戦マニュアル型のカードUI・図解・折りたたみ詳細・用語統一を実装してください。

実装前に変更方針を簡単に要約し、その後コード修正に入ってください。
```

---

# 21. 完了条件

この実装の完了条件は次の通り。

* 作戦マニュアルとして読めるUIになっている
* 初心者が概要だけ読んでもゲームの核が分かる
* 詳細を開けば正確な数値仕様が確認できる
* ガイド・チュートリアル・HUDの用語が一致している
* 主要な概念に図解がある
* 情報戦がゲームの中心として伝わる
* 既存のゲームロジックが変わっていない
* 既存テストまたは手動確認で主要機能が壊れていない

---

# 22. 実装状況（2026-06 時点）

ゲームロジックは変更していない。以下は **UX・文案・導線** の実装進捗。

## 完了（Phase A）

* 作戦マニュアル（ボトムシート）のカード型 UI・12章構成
* データ駆動（`lib/features/how_to_play/`）
* 詳細ルール章・折りたたみ詳細
* 章インデックス・関連リンク
* 旧 `how_to_play_content.dart` は `guide_sections.dart` に統合済み

## 完了（Phase B）

* 優先5種＋章レベル図解（`guide_diagram_views.dart`）
* `HelpFlowDiagram` を告発・エリア外・スキル設置で再利用
* `HelpFactionDiagram` / `HelpMapConceptDiagram` は未接続（互換のため残置）

## 完了（Phase C）

* 役職別チュートリアル文案（`tutorial_copy.dart`）
* 完了画面の関連ガイドチップ → 作戦マニュアル該当章
* ミッション表示・本鬼／人狼／匿名痕跡の用語整理

## 未対応（意図的に後回し）

* **HUD・通知・イベントログの全文言統一**（`07_CopyWriting.md` 全体）— 別 PR 想定
* **作戦マニュアルの専用 Screen 化**（ボトムシートは維持）
* **脱落後チュートリアル**（残響体・復讐の鬼影）
* **チュートリアル高度演出**（匿名痕跡タップ・パニック警告・複数痕跡追跡など）
* **チュートリアル開始画面**（スキップ／作戦マニュアル直開きの専用 UI）
* **図解の未実装分**（情報の強さ・痕跡をつなぐ・拘束分岐フロー等、`06_Diagrams.md` 参照）
* **`09_FutureIdeas.md`** の内容（アニメ図解・シミュレーター等）

## 既知の表記差（許容）

* ゲーム全体の役職表示名は **「鬼」**（`PlayerRole.hunter.displayName`）
* ガイド・告発・勝敗説明では **「本鬼」**（`GuideTerms.trueOni`）
* 試合中ボタンラベルは引き続き **「遊び方」**（HUD 統一の対象外）
