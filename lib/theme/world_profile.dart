enum WorldProfile {
  horror,
  sport,
  sciFi,
  arg,
}

extension WorldProfileLabel on WorldProfile {
  String get label {
    switch (this) {
      case WorldProfile.horror:
        return 'Urban Horror';
      case WorldProfile.sport:
        return 'Sport Radar';
      case WorldProfile.sciFi:
        return 'Sci-Fi HUD';
      case WorldProfile.arg:
        return 'ARG Signal';
    }
  }
}
