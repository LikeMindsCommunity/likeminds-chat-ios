Pod::Spec.new do |spec|
  spec.name         = 'LikeMindsChatUI'
  spec.summary      = 'LikeMinds Chat UI official iOS SDK'
  spec.homepage     = 'https://likeminds.community/'
  spec.version      = '1.2.0'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.authors      = { 'pushpendrasingh' => 'pushpendra.singh@likeminds.community' }
  spec.source       = { :git => "https://github.com/LikeMindsCommunity/likeminds-chat-ios.git", :tag => spec.version }
  
  spec.source_files = 'LMChatUI_iOS/LMChatUI_iOS/Source/**/*.swift'
  spec.resource_bundles = {
     'LikeMindsChatUI' => ['LMChatUI_iOS/LMChatUI_iOS/Source/**/*.{xcassets}']
  }
  
  spec.ios.deployment_target = '13.0'
  spec.swift_version = '5.0'
  spec.requires_arc = true

  spec.dependency 'Kingfisher', '~> 7.0'
end
