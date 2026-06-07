import 'package:flutter/material.dart';

/// ホスト向け: Maps API キー未設定時の警告。
class MapsApiKeyBanner extends StatelessWidget {
  const MapsApiKeyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.map_outlined, color: scheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '地図 API キーが未設定です。タイルが表示されない場合は、'
                'ビルド時に GOOGLE_MAPS_API_KEY を指定してください。',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onTertiaryContainer,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
