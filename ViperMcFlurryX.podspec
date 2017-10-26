Pod::Spec.new do |s|

  s.name         = "ViperMcFlurryX"
  s.version      = "1.6.1"
  s.summary      = "Fork of Rambler ViperMcFlurry framework."

  s.homepage         = "https://github.com/ladeiko/ViperMcFlurry/tree/master"
  s.license          = 'MIT'
  s.authors           = { "Siarhei Ladzeika" => "sergey.ladeiko@gmail.com" }
  s.source           = { :git => "https://github.com/ladeiko/ViperMcFlurry.git", :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'
  s.requires_arc = true

  s.source_files =  "Source/*.{h,m}"
  s.dependency 'ViperMcFlurrySwiftFix'

end
