import 'package:flutter/material.dart';

class SearchResultItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? leadingImageUrl;
  final IconData placeholderIcon;
  final Color? iconColor;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingImageUrl,
    required this.placeholderIcon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: leadingImageUrl != null && leadingImageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  leadingImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    placeholderIcon, 
                    color: iconColor ?? Colors.blue
                  ),
                ),
              )
            : Icon(placeholderIcon, color: iconColor ?? Colors.blue),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}
