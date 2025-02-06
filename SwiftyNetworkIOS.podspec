
Pod::Spec.new do |s|
  s.name             = 'SwiftyNetworkIOS'
  s.version          = '1.2.9'
  s.summary          = 'SwiftyNetworkIOS'
  s.homepage         = 'https://github.com/oahhariri/SwiftyNetworkIOS'
  s.author           = { 'Abdulrahman Hariri' => 'oahhariri@gmail.com' }
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.source           = { :git => 'https://github.com/oahhariri/SwiftyNetworkIOS.git', :tag => s.version.to_s }
  s.swift_version = '5.0'
  s.platform = :ios, "13"
  s.source_files = 'Sources/SwiftyNetworkIOS/**/*'
  #s.resource_bundles = {'SwiftyJSON' => ['Source/*.xcprivacy'],'Alamofire' => ['Source/*.xcprivacy']}
  s.dependency 'SwiftyJSON', '~> 5.0.2'
  s.dependency 'Alamofire',  '~> 5.9.1'
  
end
