Pod::Spec.new do |s|
  s.name         = "BWObjectMapping"
  s.version      = "0.4.2"
  s.summary      = "Small library that parse JSON and map it to any object, works with NSManagedObject."
  s.homepage     = "https://github.com/brunow/BWObjectMapping"
  s.license      = 'Apache License 2.0'
  s.author       = { "Bruno Wernimont" => "hello@brunowernimont.be" }
  s.source       = { :git => "https://github.com/brunow/BWObjectMapping.git", :tag => "0.4.2" }
  s.platform     = :ios, '5.0'
  s.source_files = 'BWObjectMapping/*.{h,m}'
  s.requires_arc = true
  s.frameworks = 'CoreData'
end