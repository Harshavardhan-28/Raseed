import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  /// Uploads a receipt image from a file path to Cloud Storage
  /// and returns the public download URL.
  Future<String?> uploadReceiptImageFromPath(String imagePath) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("User must be logged in to upload an image.");
    }

    try {
      // 1. Create a unique path for the file
      final String fileExtension = imagePath.split('.').last;
      final String fileName = '${const Uuid().v4()}.$fileExtension';
      final String filePath = 'receipts/${user.uid}/$fileName';

      // 2. Get a reference to the storage location
      final Reference ref = _storage.ref().child(filePath);

      // 3. Upload the file
      print("Uploading receipt image to: $filePath");
      UploadTask uploadTask = ref.putFile(File(imagePath));

      // 4. Await the upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // 5. Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Upload complete. URL: $downloadUrl");

      return downloadUrl;
    } on FirebaseException catch (e) {
      print("Error uploading file: $e");
      throw Exception("Failed to upload image: ${e.message}");
    }
  }

  /// Prompts the user to pick an image from gallery, uploads it to Cloud Storage,
  /// and returns the public download URL.
  /// Returns null if the user cancels.
  Future<String?> uploadReceiptImageFromGallery() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("User must be logged in to upload an image.");
    }

    // 1. Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      print("No image selected.");
      return null; // User canceled the picker
    }

    return await uploadReceiptImageFromPath(image.path);
  }

  /// Prompts the user to take a photo with camera, uploads it to Cloud Storage,
  /// and returns the public download URL.
  /// Returns null if the user cancels.
  Future<String?> uploadReceiptImageFromCamera() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("User must be logged in to upload an image.");
    }

    // 1. Take a photo
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) {
      print("No photo taken.");
      return null; // User canceled the camera
    }

    return await uploadReceiptImageFromPath(image.path);
  }

  /// Deletes an image from Cloud Storage using its download URL
  Future<bool> deleteReceiptImage(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      print("Image deleted successfully: $downloadUrl");
      return true;
    } on FirebaseException catch (e) {
      print("Error deleting image: $e");
      return false;
    }
  }
}
