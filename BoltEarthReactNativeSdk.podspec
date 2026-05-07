Pod::Spec.new do |s|

  s.name         = "BoltEarthReactNativeSdk"
  s.version      = "1.0.0"
  s.summary      = "BoltEarth React Native SDK"

  s.description  = <<-DESC
    React Native wrapper for BoltEarth iOS SDK
  DESC

  s.homepage     = "https://bolt.earth"

  s.license      = {
    :type => "MIT"
  }

  s.author       = {
    "BoltEarth" => "support@bolt.earth"
  }

  s.platform     = :ios, "15.1"

  s.source       = {
    :git => "https://github.com/YOUR_USERNAME/bolt-earth-react-native-sdk.git",
    :tag => s.version.to_s
  }

  s.source_files = "ios/**/*.{swift,m,h}"

  s.dependency "React-Core"

  s.dependency "BoltEarthUiSdkCore"

  s.swift_version = "5.0"

  # Important for RN + dynamic frameworks
  s.static_framework = false

end