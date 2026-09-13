enum VoiceLanguage {
  english(
    code: 'en-IN',
    displayName: 'English (Indian Accent)',
    nativeName: 'English',
    region: 'Pan-India / NER',
    flagEmoji: '🇮🇳',
  ),
  hindi(
    code: 'hi-IN',
    displayName: 'Hindi',
    nativeName: 'हिन्दी',
    region: 'National',
    flagEmoji: '🇮🇳',
  ),
  assamese(
    code: 'as-IN',
    displayName: 'Assamese',
    nativeName: 'অসমীয়া',
    region: 'Assam / Brahmaputra Valley',
    flagEmoji: '🌾',
  ),
  khasi(
    code: 'kha-IN',
    displayName: 'Khasi',
    nativeName: 'Ka Ktien Khasi',
    region: 'Meghalaya / Khasi Hills',
    flagEmoji: '⛰️',
  ),
  manipuri(
    code: 'mni-IN',
    displayName: 'Manipuri (Meitei)',
    nativeName: 'মৈতৈলোন্',
    region: 'Manipur / Imphal Valley',
    flagEmoji: '🌺',
  );

  final String code;
  final String displayName;
  final String nativeName;
  final String region;
  final String flagEmoji;

  String get label => displayName;

  const VoiceLanguage({
    required this.code,
    required this.displayName,
    required this.nativeName,
    required this.region,
    required this.flagEmoji,
  });
}
