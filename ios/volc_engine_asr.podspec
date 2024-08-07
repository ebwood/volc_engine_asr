#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint volc_engine_asr.podspec` to validate before publishing.
#

Pod::Spec.new do |s|
  s.name             = 'volc_engine_asr'
  s.version          = '0.0.4'
  s.summary          = 'volc speech engine asr for flutter'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'

  # s.source = 'https://github.com/CocoaPods/Specs.git'
  # s.source = 'https://github.com/volcengine/volcengine-specs.git'
   s.dependency 'SpeechEngineAsrToB', '1.1.6'

  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
