Pod::Spec.new do |s|

  s.name         = "VIMUpload"
  s.version      = "1.1.1"
  s.summary      = "The Vimeo iOS Upload SDK"
  s.description  = <<-DESC
                   VIMUpload is an Objective-C library that enables upload of videos to Vimeo.
                   DESC

  s.homepage     = "https://github.com/vimeo/VIMUpload"
  s.license      = "MIT (example)"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.authors = { "Alfie Hanssen" => "alfiehanssen@gmail.com",
                "Rob Huebner" => "robh@vimeo.com",
                "Gavin King" => "gavin@vimeo.com"}

  s.social_media_url = "http://twitter.com/vimeo"

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/vimeo/VIMUpload.git", :tag => s.version.to_s }
  s.source_files  = "VIMUpload", "VIMUpload/**/*.{h,m}"

  s.frameworks = "Foundation", "AVFoundation", "AssetsLibrary", "Photos", "MobileCoreServices", "UIKit"
  s.requires_arc = true

  s.subspec 'AFNetworking' do |ss|
    ss.dependency	'AFNetworking', '2.6.3'
  end

end
