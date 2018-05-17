import 'dart:async';
import 'dart:convert';
import 'dart:io';

class Certificate {
  final String key;
  final String certificate;

  Certificate(this.key, this.certificate);

  Map<String, String> toMap() {
    return {
      "key": key,
      "certificate": certificate,
    };
  }

  static Future<Certificate> generate(CertificateType type) async {
    final arguments = ['gencert', '-loglevel=5'];
    switch (type) {
      case CertificateType.CA:
        arguments.addAll([
          '-initca',
          './csr/ca.json',
        ]);
        break;
      case CertificateType.SERVER:
        arguments.addAll([
          '-ca=./certificate/certificate.pem',
          '-ca-key=./certificate/key.pem',
          '-profile=www',
          './csr/server.json',
        ]);
        break;
      case CertificateType.CLIENT:
        arguments.addAll([
          '-ca=./certificate/certificate.pem',
          '-ca-key=./certificate/key.pem',
          '-profile=client',
          './csr/client.json',
        ]);
        break;
    }

    final completer = new Completer();

    String error = "";
    String encodedJson = "";

    final cfSslProcess = await Process.start('cfssl', arguments);

    cfSslProcess.stderr.transform(utf8.decoder).listen((data) {
      error += data;
    });

    cfSslProcess.stdout.transform(utf8.decoder).listen((data) {
      encodedJson += data;
    });

    await cfSslProcess.exitCode;

    if (error.isNotEmpty) {
      completer.completeError(error);
    } else {
      final decodedJson = json.decode(encodedJson);
      final certificate = new Certificate(
        decodedJson['key'],
        decodedJson['cert'],
      );
      completer.complete(certificate);
    }

    return completer.future;
  }
}

enum CertificateType {
  CA,
  CLIENT,
  SERVER,
}
