Pod::Spec.new do |s|
  s.name         = 'DataCache'
  s.version      = '1.6.1'
  s.summary      = 'Simplest way to cache data on memory and disk'
  s.homepage     = 'https://github.com/huynguyencong/DataCache'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.source       = { :git => 'https://github.com/huynguyencong/DataCache.git', :tag => "#{s.version}" }
  s.author       = { 'Huy Nguyen Cong' => 'https://github.com/huynguyencong' }
  s.ios.deployment_target = '13.0'
  s.source_files = 'Sources/*.{swift}'
  s.requires_arc = true
  s.swift_versions = ['5.7.1']
end
