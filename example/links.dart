import 'dart:io';
import 'dart:math';
import 'package:rxdart/rxdart.dart';
import 'package:secretary/secretary.dart';

void main(List<String> args) async {
  final fileDataList = List.generate(
      20, (i) => FileData(i.toString(), Random().nextInt(100000).toString()));

  final uploadSec = Secretary<String, Result<StorageFile, int>>(
    maxAttempts: 5,
    maxConcurrentTasks: 3,
    validator: Validators.resultOk,
  );

  final createSec = Secretary<String, Result<FirestoreDoc, int>>(
    maxAttempts: 5,
    maxConcurrentTasks: 3,
    validator: Validators.resultOk,
  );

  // link the two secretaries
  uploadSec.link(createSec, (e) => createDoc(e.object!));
  // alternatively:
  // uploadSec.resultStream
  //     .listen((e) => createSec.add(e.object!.id, () => createDoc(e.object!)));

  // feedback
  uploadSec.resultStream.listen((e) => print('Uploaded file: ${e.object!.id}'));
  createSec.resultStream.listen(
      (e) => print('Created doc: ${e.object!.id} (${e.object!.fileId})'));

  // errors
  uploadSec.errorStream.listen(
      (e) => print('Error uploading file: ${e.key} [${e.attempts} attempts, '
          'final: ${e.isFinal}]'));
  createSec.errorStream.listen(
      (e) => print('Error creating doc: ${e.key} [${e.attempts} attempts, '
          'final: ${e.isFinal}]'));
  // you would probably also want to check for final failures here and clean
  // up the file you uploaded and restart or something

  // add the files to the first secretary to upload
  for (FileData f in fileDataList) {
    uploadSec.add(f.id, () => uploadFile(f));
  }

  final countStream = Rx.combineLatest2<SecretaryState, SecretaryState, int>(
      uploadSec.stateStream,
      createSec.stateStream,
      (a, b) =>
          a.active.length + a.queue.length + b.active.length + b.queue.length);

  await for (int c in countStream) {
    // end this script when the list is done
    if (c == 0) exit(0);
  }
}

/// Returns either the record of the file in storage, or an error code.
Future<Result<StorageFile, int>> uploadFile(FileData data) async {
  // upload the file
  await Future.delayed(Duration(milliseconds: Random().nextInt(1000) + 500));
  int result = Random().nextInt(10);
  return result > 8 ? Result.error(403) : Result.ok(StorageFile(data.id));
}

/// Returns either the ID of the firestore doc, or an error code.
Future<Result<FirestoreDoc, int>> createDoc(StorageFile file) async {
  // create the doc
  await Future.delayed(Duration(milliseconds: Random().nextInt(1000) + 500));
  int result = Random().nextInt(10);
  String id = Random().nextInt(100000000).toString();
  return result > 8
      ? Result.error(403)
      : Result.ok(FirestoreDoc(id: id, fileId: file.id));
}

class FileData {
  final String id;
  final String data;
  const FileData(this.id, this.data);
}

class StorageFile {
  final String id;
  const StorageFile(this.id);
}

class FirestoreDoc {
  final String id;
  final String fileId;
  const FirestoreDoc({required this.id, required this.fileId});
}
