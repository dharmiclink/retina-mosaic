#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint nexthria_cv.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'nexthria_cv'
  s.version          = '0.1.0'
  s.summary          = 'Native FFI plugin for Nexthria retinal scoring and mosaicking.'
  s.description      = <<-DESC
Native C++ plugin skeleton for Nexthria frame utility scoring, operator guidance, and live mosaicking.
                       DESC
  s.homepage         = 'https://nexthria.example'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nexthria' => 'engineering@nexthria.example' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*', 'src/**/*.{cc,c,h,hpp}'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17'
  }
  s.swift_version = '5.0'
end
