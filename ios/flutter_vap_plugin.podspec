#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_vap_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_vap_plugin'
  s.version          = '0.2.0'
  s.summary          = 'Flutter plugin for playing Tencent VAP animation videos.'
  s.description      = <<-DESC
A Flutter plugin for playing Tencent VAP animation videos on Android and iOS,
supporting local, asset sources with playback callbacks and loop control.
                       DESC
  s.homepage         = 'https://github.com/Matkurban/flutter_vap_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Matkurban' => 'matkurban@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_vap_plugin/Sources/flutter_vap_plugin/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'QGVAPlayer'
  s.platform = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {
    'flutter_vap_plugin_privacy' => ['flutter_vap_plugin/Sources/flutter_vap_plugin/PrivacyInfo.xcprivacy']
  }
end
