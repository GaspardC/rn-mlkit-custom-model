
Pod::Spec.new do |s|
  s.name         = "RNMlkitCustomModel"
  s.version      = "1.0.0"
  s.summary      = "RNMlkitCustomModel"
  s.description  = <<-DESC
                  RNMlkitCustomModel
                   DESC
  s.homepage     = ""
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/author/RNMlkitCustomModel.git", :tag => "master" }
  s.source_files  = "RNMlkitCustomModel/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  s.dependency "Firebase"

end

  