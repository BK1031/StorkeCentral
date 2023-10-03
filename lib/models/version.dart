import 'dart:math';

class Version {
  int major = 0;
  int minor = 0;
  int patch = 0;
  int build = 0;

  Version(String version) {
    major = int.parse(version.split('.')[0]);
    minor = int.parse(version.split('.')[1]);
    patch = int.parse((version.split('.')[2]).split('+')[0]);
    build = int.parse((version.split('.')[2]).split('+')[1]);
  }

  @override
  String toString() {
    return "$major.$minor.$patch";
  }

  int getVersionCode() {
    return (major * pow(10, 9) + minor * pow(10, 6) + patch * pow(10, 3) + build).toInt();
  }

  int getBuild() {
    return build;
  }

}