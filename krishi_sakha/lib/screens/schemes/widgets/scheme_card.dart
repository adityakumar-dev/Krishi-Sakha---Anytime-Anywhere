import 'package:flutter/material.dart';
import 'package:krishi_sakha/models/scheme_meta_model.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';

class SchemeCard extends StatelessWidget {
  final SchemeModel scheme;
  final VoidCallback? onTap;

  const SchemeCard({
    super.key,
    required this.scheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with level badge
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with badges
                  Row(
                    children: [
                      _buildLevelBadge(),
                      const SizedBox(width: 8),
                      if (scheme.schemeFor != null) _buildSchemeForBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Scheme name
                  Text(
                    scheme.schemeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlack,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (scheme.schemeShortTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      scheme.schemeShortTitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Brief description
                  if (scheme.briefDescription != null)
                    Text(
                      scheme.briefDescription!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 12),

                  // State and Ministry info
                  _buildInfoRow(),

                  const SizedBox(height: 12),

                  // Tags
                  if (scheme.tags != null && scheme.tags!.isNotEmpty)
                    _buildTags(),
                ],
              ),
            ),

            // Bottom info bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.haraColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Categories
                  if (scheme.schemeCategory != null && scheme.schemeCategory!.isNotEmpty)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              scheme.schemeCategory!.first,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (scheme.priority != null)
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Priority ${scheme.priority!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge() {
    final isState = scheme.level?.toLowerCase() == 'state';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isState
            ? Colors.blue.shade50
            : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isState ? Icons.location_city_rounded : Icons.public_rounded,
            size: 14,
            color: isState ? Colors.blue.shade700 : Colors.purple.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            scheme.level ?? 'Unknown',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isState ? Colors.blue.shade700 : Colors.purple.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeForBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        scheme.schemeFor!,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        if (scheme.beneficiaryState != null &&
            scheme.beneficiaryState!.isNotEmpty) ...[
          Icon(
            Icons.place_outlined,
            size: 16,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              scheme.beneficiaryState!.take(2).join(', ') +
                  (scheme.beneficiaryState!.length > 2
                      ? ' +${scheme.beneficiaryState!.length - 2}'
                      : ''),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (scheme.nodalMinistryName != null) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.account_balance_outlined,
            size: 16,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              scheme.nodalMinistryName!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTags() {
    final displayTags = scheme.tags!.take(3).toList();
    final remaining = scheme.tags!.length - 3;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displayTags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.haraColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.haraColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$remaining',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
