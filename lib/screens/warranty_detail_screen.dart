import 'package:flutter/material.dart';
import 'warranties_screen.dart';

class WarrantyDetailScreen extends StatelessWidget {
  final WarrantyItem warranty;

  const WarrantyDetailScreen({super.key, required this.warranty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Warranty Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareWarranty(context),
            tooltip: 'Share',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildProductHeader(),
            const SizedBox(height: 12),
            _buildWarrantyStatus(),
            const SizedBox(height: 12),
            _buildPurchaseInfo(),
            const SizedBox(height: 12),
            _buildReceiptSection(),
            const SizedBox(height: 12),
            _buildStoreLocation(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: warranty.urgencyColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              warranty.categoryIcon,
              color: warranty.urgencyColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warranty.productName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  warranty.category,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warranty.urgencyColor.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warranty.urgencyColor.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            warranty.isExpired ? Icons.error : Icons.shield,
            color: warranty.urgencyColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warranty.urgencyText,
                  style: TextStyle(
                    color: warranty.urgencyColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  warranty.isExpired ? 'Warranty expired' : 'Warranty active',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Purchase Information',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Store', warranty.storeName),
          _buildInfoRow('Purchase Date', _formatDate(warranty.purchaseDate)),
          _buildInfoRow(
            'Warranty Expiry',
            _formatDate(warranty.warrantyExpiry),
          ),
          _buildInfoRow('Product ID', warranty.id.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receipt',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _showReceiptFullScreen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  warranty.receiptImageUrl.isNotEmpty
                      ? Image.network(
                        warranty.receiptImageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(child: Text('No receipt image')),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreLocation() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFF64B5F6), size: 20),
              SizedBox(width: 8),
              Text(
                'Store Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            warranty.storeLocation,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _openMaps,
            icon: const Icon(Icons.map, size: 18),
            label: const Text('View on Map'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64B5F6),
              side: const BorderSide(color: Color(0xFF64B5F6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primary Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getSupportAction,
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Get Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _visitWebsiteAction,
                  icon: const Icon(Icons.language),
                  label: const Text('Visit Website'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64B5F6),
                    side: const BorderSide(color: Color(0xFF64B5F6)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Secondary Actions
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _setReminder(context),
                  icon: const Icon(Icons.notifications),
                  label: const Text('Set Reminder'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              Expanded(
                child: TextButton.icon(
                  onPressed: () => _exportWarranty(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _getWarrantyPeriod() {
    final duration = warranty.warrantyExpiry.difference(warranty.purchaseDate);
    return (duration.inDays / 365).round();
  }

  void _showReceiptFullScreen() {
    // TODO: Implement full-screen receipt viewer
  }

  void _openMaps() {
    // TODO: Implement map navigation
  }

  void _getSupportAction() {
    // TODO: Open support URL or contact form
  }

  void _visitWebsiteAction() {
    // TODO: Open website URL
  }

  void _shareWarranty(BuildContext context) {
    // TODO: Implement warranty sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Warranty details copied to clipboard')),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit screen
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Warranty'),
            content: const Text(
              'Are you sure you want to delete this warranty? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to warranties list
                  // TODO: Implement actual deletion
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _setReminder(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Set Reminder'),
            content: const Text(
              'When would you like to be reminded about this warranty?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminder set for 30 days before expiry'),
                    ),
                  );
                },
                child: const Text('30 Days Before'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminder set for 7 days before expiry'),
                    ),
                  );
                },
                child: const Text('7 Days Before'),
              ),
            ],
          ),
    );
  }

  void _exportWarranty(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Export Warranty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Export as PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Warranty exported as PDF')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Export as Image'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Warranty exported as image'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_snippet),
                  title: const Text('Export as Text'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Warranty details copied to clipboard'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }
}
