import 'package:version/version.dart';

bool isOutdated(String current, String latest) {
  Version currentVersion = Version.parse(current);
  Version latestVersion = Version.parse(latest);
  return latestVersion > currentVersion;
}