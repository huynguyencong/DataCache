Pod::Spec.new do |s|
  s.name         = 'DataCache'
  s.version      = '1.0'
  s.summary      = 'Cache data to memory and disk'
  s.homepage     = 'https://github.com/huynguyencong/Cache'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.source       = { :git => 'https://github.com/huynguyencong/Cache.git', :tag => "#{s.version}" }
  s.author       = { 'Huy Nguyen Cong' => 'https://github.com/huynguyencong' }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/*.{swift}'
  s.requires_arc = true
end