import 'package:flutter/material.dart';

/// 遊び方の説明ボトムシート。
void showHowToPlaySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('遊び方', style: Theme.of(ctx).textTheme.titleLarge),
        const SizedBox(height: 12),
        const ListTile(
          leading: Icon(Icons.flag_outlined),
          title: Text('流れ'),
          subtitle: Text(
            'タイトル → ルーム/エリア/ルール設定 → 開始 → 役職/スキル確認 → 試合 → 結果 → 軌跡再生',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.visibility_off_outlined),
          title: Text('基本ルール'),
          subtitle: Text(
            '通常はライブ位置を見せません。位置暴露・情報屋・イベント・スキルで情報が出ます。',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.shield_outlined),
          title: Text('安全地帯'),
          subtitle: Text(
            'ステルスチャージを得て、装備中スキルの再使用待ちを回復します。使用後は移動します。',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.storefront_outlined),
          title: Text('情報屋'),
          subtitle: Text(
            '鬼情報を一時的に取得します。手に入れた情報はマップ上に10分ほど痕跡として残ります。',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.videocam_outlined),
          title: Text('監視カメラ'),
          subtitle: Text(
            '小さい罠です。踏むとイベントログに残り、逃走中のルート選びに影響します。',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.front_hand_outlined),
          title: Text('捕獲'),
          subtitle: Text(
            '鬼の接触圏に一定時間入るとロックされ、ロック中にBLE接触すると捕獲です。',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.cloud_sync_outlined),
          title: Text('オンラインルーム'),
          subtitle: Text(
            'ホストが開始・終了すると他の参加者の画面も連動します（各端末でギミック配置は独立）。',
          ),
        ),
      ],
    ),
  );
}
