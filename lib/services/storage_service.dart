import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // This function opens the file explorer and uploads the image
  Future<String?> uploadMenuImage(String bizId, String itemName) async {
    try {
      // 1. Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.first.bytes != null) {
        Uint8List fileBytes = result.files.first.bytes!;
        String fileName =
            "${itemName}_${DateTime.now().millisecondsSinceEpoch}.jpg";

        // 2. Upload to Firebase Storage path: businesses/BIZ-ID/menu/image.jpg
        Reference ref =
            _storage.ref().child('businesses/$bizId/menu/$fileName');

        UploadTask uploadTask = ref.putData(fileBytes);
        TaskSnapshot snapshot = await uploadTask;

        // 3. Get the permanent URL
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      }
    } catch (e) {
      print("❌ Upload Error: $e");
    }
    return null;
  }
}
