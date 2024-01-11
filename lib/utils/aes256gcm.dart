import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';


const int KEY_LENGTH = 32;
const int NONCE_LENGTH = 12;

class Aes256Gcm {

  static String keygen(int length) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  static String encrypt(String plaintext, String key) {
    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

    Random random = Random.secure();
    // generate 12 byte nonce using random
    final nonceGen = Uint8List(12);
    for (int i = 0; i < NONCE_LENGTH; i++) {
      nonceGen[i] = random.nextInt(256);
    }
    // print("nonce: ${hex.encode(nonceGen)}");
    // print("ecrypting using: $key");

    final keyParam = KeyParameter(keyBytes);
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(keyParam, 128, nonceGen, Uint8List(0));
    cipher.init(true, params);

    final ciphertext = cipher.process(plaintextBytes);
    // print("ciphertext: ${hex.encode(ciphertext)}");

    final encryptedData = Uint8List.fromList(ciphertext);
    final nonce = params.nonce;
    final encryptedBytes = Uint8List.fromList([...nonce, ...encryptedData]);

    final encryptedString = hex.encode(encryptedBytes);
    // print("encryptedData: $encryptedString");
    return encryptedString;
  }

}