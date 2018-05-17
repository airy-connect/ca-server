import 'dart:async';
import 'dart:io';

import 'package:rpc/rpc.dart';

import 'certificate.dart';

const availableCommands = '''

Available commands:
  generate-certificate
  start
''';

Future<void> main(List<String> args) async {
  final certificateFile = new File('./certificate/certificate.pem');
  final certificateKeyFile = new File('./certificate/key.pem');

  switch (args.isNotEmpty ? args.first : null) {
    case 'generate-certificate':
      if (await certificateFile.exists() && await certificateKeyFile.exists()) {
        stdout.write(
          'Certificates already generated. Do you want to replace them? y/N\n',
        );
        if (stdin.readLineSync().toLowerCase() != 'y') return null;
      }
      final certificate = await Certificate.generate(CertificateType.CA);
      await certificateFile.writeAsString(certificate.certificate);
      await certificateKeyFile.writeAsString(certificate.key);
      break;

    case 'start':
      if (!await certificateFile.exists() ||
          !await certificateKeyFile.exists()) {
        return stderr.write('Certificates not found. Please generate them.\n');
      }
      final ApiServer apiServer = new ApiServer();
      apiServer.addApi(new Api());
      HttpServer server = await HttpServer.bind(
        InternetAddress.ANY_IP_V4,
        8081,
      );
      server.listen(apiServer.httpRequestHandler);
      break;

    default:
      return stderr.write('No command is given.\n$availableCommands');
  }
}

@ApiClass(version: 'v1')
class Api {
  @ApiMethod(path: 'certificate/server')
  Future<Certificate> getServerCertificate() async {
    return await Certificate.generate(CertificateType.SERVER);
  }

  @ApiMethod(path: 'certificate/client')
  Future<Certificate> getClientCertificate() async {
    return await Certificate.generate(CertificateType.CLIENT);
  }
}
