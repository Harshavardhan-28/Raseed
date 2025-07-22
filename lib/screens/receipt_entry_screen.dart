import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'home_screen.dart';
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
        setState(() {
          _storeNameController.text = data['storeName'] ?? '';
          _totalAmountController.text = data['totalAmount']?.toString() ?? '';
          if (data['transactionDate'] != null) {
            _transactionDate = DateTime.tryParse(data['transactionDate']);
          } else if (data['date'] != null) {
            _transactionDate = DateTime.tryParse(data['date']);
          }
          if (data['lineItems'] != null && data['lineItems'] is List) {
            _lineItems = List<Map<String, dynamic>>.from(data['lineItems']);
          } else {
            _lineItems = [];
          }
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
          ? const Center(child: CircularProgressIndicator())
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: item['description']?.toString() ?? '',
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
                      onPressed: () {
                        if (_storeNameController.text.isNotEmpty && _totalAmountController.text.isNotEmpty) {
                          final transaction = {
                            'storeName': _storeNameController.text,
                            'totalAmount': _totalAmountController.text,
                            'transactionDate': _transactionDate?.toIso8601String(),
                            'lineItems': _lineItems,
                          };
                          Navigator.of(context).pop(transaction);
                        }
                      },
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
