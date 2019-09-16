require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
    s.name           = package['name']
    s.version        = package['version']
    s.summary        = package['description']
    s.description    = package['description']
    s.license        = package['license']
    s.author         = package['author']
    s.homepage       = package['repository']
    s.source         = { :git => 'https://github.com/miniyarov/react-native-network-extension.git' }
  
    s.requires_arc   = true
    s.platform       = :ios, '9.0'
    s.swift_version  = '3.2'
  
    s.preserve_paths = '*.js'
    s.source_files   = 'ios/*.{h,m}', 'ios/*.swift'
  
    s.dependency 'React'
  end
  