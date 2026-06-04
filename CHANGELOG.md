## 0.2.0

* **Breaking:** Minimum Flutter 3.44 / Dart 3.12.
* Migrate Android build to Flutter built-in Kotlin.
* Add iOS Swift Package Manager support (with local QGVAPlayer SPM package).
* Android Surface API migration assessed as not applicable (PlatformView-based).

## 0.1.6

* expose an api when platfromView created
* Add support for Google's 16KB requirement
* Finished migration to UIScene lifecycle. See https://flutter.dev/to/uiscene-migration for details.

## 0.1.5

* Change deleteOnEnd argument type to Boolean

## 0.1.4

* deleteOnEnd param added

## 0.1.3

* Fix the issue of not being able to play local files in iOS
* Fixed the issue that the scaleType parameter did not take effect in ios

## 0.1.2

* Fixed the issue that playing another video in playback would not play

## 0.1.1

* Added the 'repeatCount' parameter to control the number of loops.
* The 'scaleType' parameter is added to support setting the video zoom type.

## 0.1.0

* Released the first stable version with support for video playback in 'vap' format for files and resources.