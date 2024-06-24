Pod::Spec.new do |spec|
  spec.name         = 'LikeMindsChatCore'
  spec.summary      = 'LikeMinds Chat official iOS SDK'
  spec.homepage     = 'https://likeminds.community/'
  spec.version      = '1.2.0'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.authors      = { 'pushpendrasingh' => 'pushpendra.singh@likeminds.community' }
  spec.source       = { :git => "https://github.com/LikeMindsCommunity/likeminds-chat-ios.git", :tag => spec.version }

  spec.source_files = 'LMChatCore_iOS/LMChatCore_iOS/Source/**/*.swift'
  spec.resource_bundles = {
     'LikeMindsChatCore' => ['LMChatCore_iOS/LMChatCore_iOS/Source/Assets/*.{xcassets}']
  }

  spec.ios.deployment_target = '13.0'
  spec.swift_version = '5.0'
  spec.requires_arc = true
  
  spec.dependency "AWSCore"
  spec.dependency "AWSCognito"
  spec.dependency "AWSS3"
  spec.dependency 'Giphy'
  spec.dependency 'LikeMindsChat'
  spec.dependency 'LikeMindsChatUI'
end
