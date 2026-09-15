#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint account_manager.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_account_manager'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin for cross-platform account management.'
  s.description      = <<-DESC
A Flutter plugin for cross-platform account management, authentication, and
background sync using native platform APIs.
                       DESC
  s.homepage         = 'https://github.com/lkrjangid1/flutter_account_manager'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Lokesh Jangid' => 'lkrjangid1@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_account_manager/Sources/flutter_account_manager/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'flutter_account_manager_privacy' => ['flutter_account_manager/Sources/flutter_account_manager/Resources/PrivacyInfo.xcprivacy']}
end
