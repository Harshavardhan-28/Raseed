import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WarrantyReceiptEntryScreen extends StatefulWidget {
  final String itemId;
  const WarrantyReceiptEntryScreen({super.key, required this.itemId});

  @override
  State<WarrantyReceiptEntryScreen> createState() =>
      _WarrantyReceiptEntryScreenState();
}

class _WarrantyReceiptEntryScreenState
    extends State<WarrantyReceiptEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _warrantyProviderController = TextEditingController();
  final _warrantyPeriodController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _purchaseDate;
  DateTime? _warrantyEndDate;
  String? _status;
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _parseReceipt() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Replace with your actual API endpoint
      final url = Uri.parse(
        'https://warranty-receipt-979444618103.europe-west1.run.app',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _itemNameController.text = data['itemName'] ?? '';
          _notesController.text = data['notes'] ?? '';
          _warrantyPeriodController.text =
              data['warrantyPeriodMonths']?.toString() ?? '';
          _status = data['status'];
          _purchaseDate =
              data['purchaseDate'] != null
                  ? DateTime.parse(data['purchaseDate'])
                  : null;
          _warrantyEndDate =
              data['warrantyEndDate'] != null
                  ? DateTime.parse(data['warrantyEndDate'])
                  : null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt parsed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to parse receipt: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWarranty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user logged in.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Construct the final map for Firestore
      final warrantyData = {
        "userId": user.uid,
        "itemName": _itemNameController.text,
        "purchaseDate":
            _purchaseDate != null ? Timestamp.fromDate(_purchaseDate!) : null,
        "warrantyPeriodMonths":
            int.tryParse(_warrantyPeriodController.text) ?? 0,
        "warrantyEndDate":
            _warrantyEndDate != null
                ? Timestamp.fromDate(_warrantyEndDate!)
                : null,
        "warrantyProvider": _warrantyProviderController.text,
        "lineItemId": widget.itemId,
        "status": _status,
        "createdAt": FieldValue.serverTimestamp(),
        "notes": _notesController.text,
      };

      await FirebaseFirestore.instance.collection('warranty').add(warrantyData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warranty saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save warranty: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _warrantyProviderController.dispose();
    _warrantyPeriodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Warranty Receipt'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF202124),
        titleTextStyle: const TextStyle(
          color: Color(0xFF202124),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_imageFile == null)
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF42A5F5),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file_outlined,
                              size: 50,
                              color: Color(0xFF42A5F5),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to Upload Receipt',
                              style: TextStyle(color: Color(0xFF42A5F5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _imageFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                if (_imageFile != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon:
                        _isLoading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.auto_fix_high),
                    label:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Parse Receipt'),
                    onPressed: _isLoading ? null : _parseReceipt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _itemNameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Please enter an item name' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _warrantyProviderController,
                  decoration: InputDecoration(
                    labelText: 'Warranty Provider',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _warrantyPeriodController,
                  decoration: InputDecoration(
                    labelText: 'Warranty Period (months)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_month),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Purchase Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.today),
                  ),
                  controller: TextEditingController(
                    text:
                        _purchaseDate == null
                            ? ''
                            : DateFormat.yMMMd().format(_purchaseDate!),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Warranty End Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.event_available),
                  ),
                  controller: TextEditingController(
                    text:
                        _warrantyEndDate == null
                            ? ''
                            : DateFormat.yMMMd().format(_warrantyEndDate!),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveWarranty,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF42A5F5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
