import 'package:flutter/material.dart';
import 'package:add_to_google_wallet/widgets/add_to_google_wallet_button.dart';
import 'dart:async';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_screen.dart';

class ReceiptEntryScreen extends StatefulWidget {
  const ReceiptEntryScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptEntryScreen> createState() => _ReceiptEntryScreenState();
}

class _ReceiptEntryScreenState extends State<ReceiptEntryScreen> {
  String? _lastSavedPass;
  final _storeNameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  DateTime? _transactionDate;
  List<Map<String, dynamic>> _lineItems = [];
  Map<String, dynamic> _apiResponseData = {};
  String? _receiptImagePath;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _showSuccessFlow = false;
  String _savedReceiptId = '';

  // Audio recording state
  AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  String? _audioFilePath;
  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
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
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
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
    setState(() {
      _isLoading = true;
    });
    final File file = File(_receiptImagePath!);
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      debugPrint('Sending image to API, size: \'${bytes.length}\' bytes');
      final response = await http.post(
        Uri.parse(
          'https://parse-receipt-python-979444618103.asia-south1.run.app',
        ),
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
          _transactionDate =
              data['date_and_time'] != null
                  ? DateTime.tryParse(data['date_and_time'])
                  : null;
          _lineItems =
              data['line_items'] is List
                  ? List<Map<String, dynamic>>.from(
                    data['line_items'].map((item) {
                      // Ensure all expected fields are present for UI and storage
                      return {
                        'description':
                            item['description'] ?? item['name'] ?? '',
                        'quantity': item['quantity'] ?? 1,
                        'price': item['price'] ?? 0.0,
                        'category': item['category'] ?? '',
                        'isFood': item['isFood'] ?? false,
                        'isRecurring': item['isRecurring'] ?? false,
                        'isWarranty': item['isWarranty'] ?? false,
                        'price_per_quantity': item['price_per_quantity'] ?? '',
                        'name':
                            item['name'] ?? '', // preserve name for fallback
                      };
                    }),
                  )
                  : [];
        });
      } else {
        debugPrint('API error: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to parse receipt: ${response.statusCode}'),
            ),
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
    setState(() {
      _isLoading = false;
    });
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
      'purchase_date':
          _transactionDate != null
              ? Timestamp.fromDate(_transactionDate!)
              : null,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  List<Map<String, dynamic>> _prepareLineItemDocuments(
    String userId,
    String receiptId,
  ) {
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
        // Add purchase_date for each line item
        'purchase_date':
            _transactionDate != null
                ? Timestamp.fromDate(_transactionDate!)
                : null,
      });
    }
    return lineItemDocs;
  }

  Future<void> _saveReceiptData() async {
    if (_storeNameController.text.isEmpty ||
        _totalAmountController.text.isEmpty ||
        _lineItems.isEmpty ||
        _transactionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields and ensure items are scanned.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final userId = await _getCurrentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not logged in.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      // Generate a random receipt number for Firestore document ID
      final String generatedReceiptId =
          DateTime.now().millisecondsSinceEpoch.toString() +
          '-' +
          (100000 +
                  (999999 - 100000) *
                      (new DateTime.now().microsecond % 1000000) ~/
                      1000000)
              .toString();
      final String? parsedReceiptNo = _apiResponseData['receipt_no'];
      if (parsedReceiptNo == null || parsedReceiptNo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Receipt number is missing from API response. Cannot save.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Prepare receipt document and include line items as a field
      final receiptRef = db.collection('receipts').doc(generatedReceiptId);
      final receiptDocumentData = _prepareReceiptDocument(userId);
      // Store the parsed receipt number in the receipt data
      receiptDocumentData['parsed_receipt_no'] = parsedReceiptNo;
      final lineItemDocumentsData = _prepareLineItemDocuments(
        userId,
        generatedReceiptId,
      );
      // Add line items to receipt document
      receiptDocumentData['line_items'] = lineItemDocumentsData;

      final batch = db.batch();
      batch.set(receiptRef, receiptDocumentData);

      // Store each line item as a separate document
      for (final lineItemData in lineItemDocumentsData) {
        final lineItemRef = db.collection('line_items').doc();
        batch.set(lineItemRef, lineItemData);
      }

      await batch.commit();

      // Generate pass for Google Wallet
      final String issuerId = '3388000000022970756';
      final String issuerEmail = 'harshavardhan.khamkar@gmail.com';
      final String passId = generatedReceiptId;
      final String passClass = 'Reciepts';
      final String storeName = _storeNameController.text;
      final String totalAmount = _totalAmountController.text;
      final String receiptNo = parsedReceiptNo;
      final String date =
          _transactionDate?.toLocal().toString().split(' ')[0] ?? '';
      final String pass = '''
      {
        "iss": "$issuerEmail",
        "aud": "google",
        "typ": "savetowallet",
        "origins": [],
        "payload": {
          "genericObjects": [
            {
              "id": "$issuerId.$passId",
              "classId": "$issuerId.$passClass",
              "genericType": "GENERIC_TYPE_UNSPECIFIED",
              "hexBackgroundColor": "#007AFF",
              "logo": {
                "sourceUri": {
                  "uri": "https://storage.googleapis.com/wallet-lab-tools-codelab-artifacts-public/pass_google_logo.jpg"
                }
              },
              "cardTitle": {
                "defaultValue": {
                  "language": "en",
                  "value": "Receipt for $storeName"
                }
              },
              "subheader": {
                "defaultValue": {
                  "language": "en",
                  "value": "Total: ₹$totalAmount"
                }
              },
              "header": {
                "defaultValue": {
                  "language": "en",
                  "value": "$receiptNo"
                }
              },
              "barcode": {
                "type": "QR_CODE",
                "value": "$passId"
              },
              "heroImage": {
                "sourceUri": {
                  "uri": "https://storage.googleapis.com/wallet-lab-tools-codelab-artifacts-public/google-io-hero-demo-only.jpg"
                }
              },
              "textModulesData": [
                {
                  "header": "DATE",
                  "body": "$date",
                  "id": "date"
                }
              ]
            }
          ]
        }
      }
      ''';
      setState(() {
        _lastSavedPass = pass;
        _savedReceiptId = generatedReceiptId;
      });

      if (mounted) {
        setState(() {
          _showSuccessFlow = true;
        });
        _showSuccessDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save receipt: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success checkmark with blue badge-like design
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1565C0), // Navy blue
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      // Wavy outer edge effect
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1565C0), // Navy blue
                              width: 8,
                            ),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D47A1), // Darker navy blue
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 60,
                              color: Colors.white,
                              weight: 800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Receipt Added Successfully!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Store: ${_storeNameController.text}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: ₹${_totalAmountController.text}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Receipt ID: $_savedReceiptId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showWalletDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0), // Navy blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showWalletDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.wallet,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Add to Google Wallet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF202124),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Keep your receipt handy by adding it to Google Wallet for quick access.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_lastSavedPass != null)
                  AddToGoogleWalletButton(
                    pass: _lastSavedPass!,
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.toString()),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      Navigator.of(context).pop();
                      _navigateToHome();
                    },
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pass added to Google Wallet!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
                      _navigateToHome();
                    },
                    onCanceled: () {
                      Navigator.of(context).pop();
                      _navigateToHome();
                    },
                    locale: const Locale('en'),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _navigateToHome();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF64B5F6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64B5F6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _totalAmountController.dispose();
    _audioRecorder?.dispose();
    super.dispose();
  }

  // Handle voice input button
  Future<void> _handleVoiceInput() async {
    if (_isRecording) {
      final path = await _audioRecorder?.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        await _sendAudioToApi(path);
      }
    } else {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice input.'),
          ),
        );
        return;
      }
      try {
        Directory tempDir = await getTemporaryDirectory();
        _audioFilePath = '${tempDir.path}/voice_receipt.wav';

        await _audioRecorder?.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: _audioFilePath!,
        );

        setState(() => _isRecording = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording... Tap the mic again to stop.'),
          ),
        );
      } catch (e) {
        debugPrint('Failed to start recorder: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not start recorder. $e')),
        );
        setState(() => _isRecording = false);
      }
    }
  }

  Future<void> _sendAudioToApi(String filePath) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("Recording failed: File does not exist.");
      }
      final fileSize = await file.length();
      debugPrint('Recorded file size: $fileSize bytes');
      if (fileSize < 1024) {
        // Increased threshold to 1KB
        throw Exception(
          "Recording is too short. Please record for at least one second.",
        );
      }

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
          'https://parse-reciept-audio-direct-979444618103.europe-west1.run.app',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'audio': base64Audio}),
      );

      debugPrint('Audio API response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Audio API response data: $data');
        _apiResponseData = data;
        setState(() {
          _storeNameController.text = data['store_name'] ?? '';
          _totalAmountController.text = data['total_amount']?.toString() ?? '';
          _transactionDate =
              data['date_and_time'] != null
                  ? DateTime.tryParse(data['date_and_time'])
                  : null;
          _lineItems =
              data['line_items'] is List
                  ? List<Map<String, dynamic>>.from(
                    data['line_items'].map((item) {
                      return {
                        'description':
                            item['description'] ?? item['name'] ?? '',
                        'quantity': item['quantity'] ?? 1,
                        'price': item['price'] ?? 0.0,
                        'category': item['category'] ?? '',
                        'isFood': item['isFood'] ?? false,
                        'isRecurring': item['isRecurring'] ?? false,
                        'isWarranty': item['isWarranty'] ?? false,
                        'price_per_quantity': item['price_per_quantity'] ?? '',
                        'name': item['name'] ?? '',
                      };
                    }),
                  )
                  : [];
        });
      } else {
        throw Exception('Failed to process audio: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception during audio processing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing voice input: $e')),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Receipt'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF202124),
        titleTextStyle: const TextStyle(
          color: Color(0xFF202124),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF5F6368),
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body:
          _isLoading
              ? const Center(child: AnimatedThreeDotLoader())
              : _showSuccessFlow
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 100,
                      color: Color(0xFF64B5F6),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Processing Complete!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202124),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Your receipt has been successfully added.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_receiptImagePath != null &&
                        File(_receiptImagePath!).existsSync())
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
                            backgroundColor: const Color(0xFF64B5F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF64B5F6),
                            elevation: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(
                            _isRecording
                                ? Icons.stop_circle_outlined
                                : Icons.mic,
                            color:
                                _isRecording
                                    ? Colors.redAccent
                                    : const Color(0xFF64B5F6),
                            size: 32,
                          ),
                          tooltip: 'Fill form by voice',
                          onPressed: _handleVoiceInput,
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
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                        const Text(
                          'Line Items',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _lineItems.add({
                                'description': '',
                                'quantity': '',
                                'price': '',
                              });
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Line Item'),
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF64B5F6),
                          ),
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
                      final description =
                          (item['description'] != null &&
                                  item['description'].toString().isNotEmpty)
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
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                ),
                                onChanged:
                                    (val) =>
                                        _lineItems[idx]['description'] = val,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue:
                                    item['quantity']?.toString() ?? '',
                                decoration: const InputDecoration(
                                  labelText: 'Qty',
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged:
                                    (val) =>
                                        _lineItems[idx]['quantity'] =
                                            double.tryParse(val) ?? val,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: item['price']?.toString() ?? '',
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged:
                                    (val) =>
                                        _lineItems[idx]['price'] =
                                            double.tryParse(val) ?? val,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
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
                          backgroundColor: const Color(0xFF64B5F6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Add Receipt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

class _AnimatedThreeDotLoaderState extends State<AnimatedThreeDotLoader>
    with SingleTickerProviderStateMixin {
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
                if (phase < 0) phase += 1.0;
                double scale =
                    0.7 + 0.6 * (0.5 + 0.5 * (1 - (phase * 2 - 1).abs()));
                return scale;
              });
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Transform.scale(
                      scale: scales[i],
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFF64B5F6),
                          shape: BoxShape.circle,
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
            color: Color(0xFF64B5F6),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
