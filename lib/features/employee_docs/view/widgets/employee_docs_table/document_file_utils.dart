String? storagePathFromPublicUrl(String fileUrl) {
  final uri = Uri.tryParse(fileUrl);
  if (uri == null) return null;
  final bucketIndex = uri.pathSegments.indexOf('employee_docs');
  if (bucketIndex == -1 || bucketIndex + 1 >= uri.pathSegments.length) {
    return null;
  }
  return uri.pathSegments.sublist(bucketIndex + 1).join('/');
}

bool isImageFile(String fileUrl) {
  final lower = fileUrl.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp');
}

String formatDocDate(DateTime? d) {
  if (d == null) return '-';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
