Pod::Spec.new do |s|

  s.name                    = "ViperMcFlurryX_Swift"
  s.module_name             = "ViperMcFlurryX_Swift"
  s.version                 = "2.0.1"
  s.summary                 = "ViperMcFlurryX - Support for VIPER concept on iOS"

  s.homepage                = "https://github.com/ladeiko/ViperMcFlurryX"
  s.license                 = 'MIT'
  s.authors                 = { "Siarhei Ladzeika" => "sergey.ladeiko@gmail.com",
                                "Cheslau Bachko" => "https://github.com/CheslauBachko" }
  
  s.source                  = { :git => "https://github.com/ladeiko/ViperMcFlurryX.git", :tag => s.version.to_s }
  
  s.ios.deployment_target   = '10.0'
  s.swift_versions          = ['4.0', '4.2', '5.0', '5.1']
  s.requires_arc            = true
  s.static_framework        = true

  s.source_files            = "SourceSwift/**/*.{Swift}"

end
