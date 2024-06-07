
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseOptions firebaseOptions = FirebaseOptions(
    projectId: "filemanagement-4efdd",
    storageBucket: "filemanagement-4efdd.appspot.com",
    apiKey: "AIzaSyDtl1zb35nNHiPb0W6AdOeYRvRE-d2KQRI",// Optional: Only if you are using Firebase Storage
    appId:"1:521646143115:android:86f23bcec8ad139dd0868e",
    messagingSenderId:"521646143115"
  );

  // Initialize Firebase with the provided options
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(FileUploadApp());
}


class FileUploadApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Upload Demo',
      home: FileUploadScreen(),
    );
  }
}

class FileUploadScreen extends StatefulWidget {
  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
  
}

class _FileUploadScreenState extends State<FileUploadScreen> {
   String _selectedFileName = 'No file selected';
   PlatformFile? pickedFile;
   UploadTask? uploadTask;
   Uint8List? pickedFileBytes;
   double _progress=0.0;
  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        PlatformFile file = result.files.first;
        String fileName = file.name;
        setState(() {
          pickedFile = result.files.first;
        _selectedFileName = pickedFile!.name;
        pickedFileBytes=result.files.first.bytes;
        });

        // Store the file in local storage or cache
        Directory appDocumentsDirectory =
            await getApplicationDocumentsDirectory();
        String filePath = '${appDocumentsDirectory.path}/$fileName';
        File selectedFile = File(filePath);
        await selectedFile.writeAsBytes(file.bytes!);

        // Show success popup
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('File Selected'),
              content: Text('$_selectedFileName is successfully selected.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }

  }
   Future<void> _uploadFile() async {
    if (pickedFile == null) {
      print("No file selected");
      return;
    }

    if (pickedFileBytes != null) {
      // For Flutter web
      final path = 'files/$_selectedFileName';
      final ref = FirebaseStorage.instance.ref().child(path);

      UploadTask uploadTask = ref.putData(pickedFileBytes!);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        });
      });
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      final urlDownload = await snapshot.ref.getDownloadURL();
      print('Download Link: $urlDownload');
    } else {
      // For Android
        if (pickedFile != null) {
          final path = 'files/${pickedFile!.name}';
          final ref = FirebaseStorage.instance.ref().child(path);
          
          UploadTask uploadTask = ref.putFile(File(pickedFile!.path!));
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            setState(() {
              _progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
            });
          });
          TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
          final urlDownload = await snapshot.ref.getDownloadURL();
          print('Download Link: $urlDownload');
        }
    } 
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Selection Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _selectFile,
              child: Text('Select File'),
            ),
            SizedBox(height: 20),
            Text(
              'Selected File: $_selectedFileName',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadFile,
              child: Text('Upload'),
            ),
            SizedBox(height: 50),
            _progress > 0
                ? LinearProgressIndicator(
                    value: _progress / 100,
                    backgroundColor: Colors.grey,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  )
                : Container(),
            
            
          ],
          
        ),
      ),
    );
  }
  
  
}