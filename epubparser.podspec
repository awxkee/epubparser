Pod::Spec.new do |s|
    s.name             = 'epubparser'
    s.version          = '1.0.1'
    s.summary          = 'EPUB parser for iOS'
    s.description      = 'Provides support for JXL files in iOS and MacOS'
    s.homepage         = 'https://github.com/awxkee/epubparser'
    s.license          = { :type => 'BSD-3', :file => 'LICENSE.md' }
    s.author           = { 'username' => 'radzivon.bartoshyk@proton.me' }
    s.source           = { :git => 'https://github.com/awxkee/epubparser.git', :tag => "#{s.version}" }
    s.ios.deployment_target = '11.0'
    s.source_files = 'Sources/epubparser/*.{swift,h,m,cpp,mm,hpp}'
    s.swift_version = ["5.3", "5.4", "5.5"]
    s.frameworks = "Foundation", "CoreGraphics", "Accelerate"
    s.libraries = 'c++'
    s.dependency 'AEXML'
    s.dependency 'ZIPFoundation'
    s.dependency 'SwiftSoup'
    s.requires_arc = true
end

