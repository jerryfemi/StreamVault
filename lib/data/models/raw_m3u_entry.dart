class RawM3uEntry {
  final Map<String, String> attributes;
  final String title;
  final String streamUrl;

  RawM3uEntry({
    required this.attributes,
    required this.title,
    required this.streamUrl,
  });
}
