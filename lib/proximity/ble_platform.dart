import 'package:flutter/foundation.dart';

bool get defaultTargetPlatformIsMobile =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
