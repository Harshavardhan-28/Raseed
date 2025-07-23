
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class ReceiptEntryScreen extends StatefulWidget {
  const ReceiptEntryScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptEntryScreen> createState() => _ReceiptEntryScreenState();
}


class _ReceiptEntryScreenState extends State<ReceiptEntryScreen> {
  final _storeNameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  DateTime? _transactionDate;
  List<Map<String, dynamic>> _lineItems = [];
  Map<String, dynamic> _apiResponseData = {};
  String? _receiptImagePath;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;



  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      debugPrint('Camera image picked: \'${pickedFile.path}\'');
      setState(() {
        _receiptImagePath = pickedFile.path;
      });
      _scanReceipt();
    } else {
      debugPrint('No image picked from camera.');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      debugPrint('Gallery image picked: \'${pickedFile.path}\'');
      setState(() {
        _receiptImagePath = pickedFile.path;
      });
      _scanReceipt();
    } else {
      debugPrint('No image picked from gallery.');
    }
  }



  Future<void> _scanReceipt() async {
    if (_receiptImagePath == null) {
      debugPrint('No image path set for scanning.');
      return;
    }
    setState(() { _isLoading = true; });
    final File file = File(_receiptImagePath!);
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      debugPrint('Sending image to API, size: \'${bytes.length}\' bytes');
      final response = await http.post(
        Uri.parse('https://parse-receipt-python-979444618103.asia-south1.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );
      debugPrint('API response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('API response data: $data');
        _apiResponseData = data;
        setState(() {
          _storeNameController.text = data['store_name'] ?? '';
          _totalAmountController.text = data['total_amount']?.toString() ?? '';
          _transactionDate = data['date_and_time'] != null ? DateTime.tryParse(data['date_and_time']) : null;
          _lineItems = data['line_items'] is List
              ? List<Map<String, dynamic>>.from(data['line_items'].map((item) {
                  // Ensure all expected fields are present for UI and storage
                  return {
                    'description': item['description'] ?? item['name'] ?? '',
                    'quantity': item['quantity'] ?? 1,
                    'price': item['price'] ?? 0.0,
                    'category': item['category'] ?? '',
                    'isFood': item['isFood'] ?? false,
                    'isRecurring': item['isRecurring'] ?? false,
                    'isWarranty': item['isWarranty'] ?? false,
                    'price_per_quantity': item['price_per_quantity'] ?? '',
                    'name': item['name'] ?? '', // preserve name for fallback
                  };
                }))
              : [];
        });
      } else {
        debugPrint('API error: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to parse receipt: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception during scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred while parsing receipt: $e')),
        );
      }
    }
    setState(() { _isLoading = false; });
  }
  Future<String?> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Map<String, dynamic> _prepareReceiptDocument(String userId) {
    return {
      'user_id': userId,
      'store_name': _storeNameController.text,
      'total_amount': double.tryParse(_totalAmountController.text) ?? 0.0,
      'tax_amount': _apiResponseData['tax_amount'] ?? 0.0,
      'currency': _apiResponseData['currency'] ?? 'INR',
      'category': _apiResponseData['category'] ?? 'General',
      'purchase_date': _transactionDate != null ? Timestamp.fromDate(_transactionDate!) : null,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  List<Map<String, dynamic>> _prepareLineItemDocuments(String userId, String receiptId) {
    final List<Map<String, dynamic>> lineItemDocs = [];
    for (final item in _lineItems) {
      lineItemDocs.add({
        'user_id': userId,
        'receipt_no': receiptId,
        // Use 'description' if present, else fallback to 'name' (API), else empty string
        'description': item['description'] ?? item['name'] ?? '',
        'quantity': item['quantity'] ?? 0,
        'price': item['price'] ?? 0.0,
        'category': item['category'] ?? 'Uncategorized',
        'isWarranty': item['isWarranty'] ?? false,
        'isFood': item['isFood'] ?? false,
        'isRecurring': item['isRecurring'] ?? false,
        'price_per_quantity': item['price_per_quantity'] ?? '',
      });
    }
    return lineItemDocs;
  }

  Future<void> _saveReceiptData() async {
    if (_storeNameController.text.isEmpty || _totalAmountController.text.isEmpty || _lineItems.isEmpty || _transactionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields and ensure items are scanned.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() { _isLoading = true; });
    final userId = await _getCurrentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not logged in.'), backgroundColor: Colors.redAccent));
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final String? receiptIdFromApi = _apiResponseData['receipt_no'];
      if (receiptIdFromApi == null || receiptIdFromApi.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Receipt number is missing from API response. Cannot save.'), backgroundColor: Colors.redAccent));
        setState(() { _isLoading = false; });
        return;
      }

      final receiptRef = db.collection('receipts').doc(receiptIdFromApi);
      final receiptDocumentData = _prepareReceiptDocument(userId);
      final lineItemDocumentsData = _prepareLineItemDocuments(userId, receiptIdFromApi);

      final batch = db.batch();
      batch.set(receiptRef, receiptDocumentData);

      for (final lineItemData in lineItemDocumentsData) {
        final lineItemRef = db.collection('line_items').doc();
        batch.set(lineItemRef, lineItemData);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt added successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save receipt: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Receipt'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: AnimatedThreeDotLoader())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_receiptImagePath != null && File(_receiptImagePath!).existsSync())
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(_receiptImagePath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImageFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Scan Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF007AFF),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _storeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Store Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _totalAmountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _transactionDate == null
                              ? 'Date: Not selected'
                              : 'Date: ${_transactionDate!.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _transactionDate = picked;
                            });
                          }
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _lineItems.add({'description': '', 'quantity': '', 'price': ''});
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Line Item'),
                        style: TextButton.styleFrom(foregroundColor: Color(0xFF007AFF)),
                      ),
                    ],
                  ),
                  if (_lineItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No line items. Tap "Add Line Item" to add.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ..._lineItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    // Ensure description is always set for UI
                    final description = (item['description'] != null && item['description'].toString().isNotEmpty)
                        ? item['description'].toString()
                        : (item['name']?.toString() ?? '');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: description,
                              decoration: const InputDecoration(labelText: 'Description'),
                              onChanged: (val) => _lineItems[idx]['description'] = val,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: item['quantity']?.toString() ?? '',
                              decoration: const InputDecoration(labelText: 'Qty'),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              onChanged: (val) => _lineItems[idx]['quantity'] = double.tryParse(val) ?? val,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item['price']?.toString() ?? '',
                              decoration: const InputDecoration(labelText: 'Price'),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              onChanged: (val) => _lineItems[idx]['price'] = double.tryParse(val) ?? val,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            tooltip: 'Remove',
                            onPressed: () {
                              setState(() {
                                _lineItems.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveReceiptData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Add Receipt',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Modern animated three-dot loader widget with loading text
class AnimatedThreeDotLoader extends StatefulWidget {
  const AnimatedThreeDotLoader({Key? key}) : super(key: key);

  @override
  State<AnimatedThreeDotLoader> createState() => _AnimatedThreeDotLoaderState();
}

class _AnimatedThreeDotLoaderState extends State<AnimatedThreeDotLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 48,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double t = _controller.value;
              // Each dot animates with a phase offset
              List<double> scales = List.generate(3, (i) {
                double phase = (t - i * 0.2) % 1.0;
                double scale = 0.7 + 0.6 * (0.5 + 0.5 * (1 - (phase * 2 - 1).abs()));
                return scale;
              });
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Transform.scale(
                      scale: scales[i],
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.15),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Analyzing receipt...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF007AFF),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
