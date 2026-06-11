/// エリア一覧から戻るときの意図。
sealed class AreaGalleryPick {
  const AreaGalleryPick();
}

/// タップしたエリアを地図プレビューで見る。
class AreaGalleryPreviewPick extends AreaGalleryPick {
  const AreaGalleryPreviewPick(this.slotId);

  final String slotId;
}
