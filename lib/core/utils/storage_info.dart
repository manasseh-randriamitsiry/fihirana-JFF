class StorageInfo {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final int itemCount;

  const StorageInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    required this.itemCount,
  });

  double get usedPercentage =>
      totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0;
  double get freePercentage =>
      totalBytes > 0 ? (freeBytes / totalBytes) * 100 : 0;

  @override
  String toString() {
    return 'StorageInfo(total: $totalBytes, used: $usedBytes, free: $freeBytes, items: $itemCount)';
  }
}
