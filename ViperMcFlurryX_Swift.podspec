Pod::Spec.new do |s|

  s.name                    = "ViperMcFlurryX_Swift"
  s.module_name             = "ViperMcFlurryX_Swift"
  s.version                 = "3.1.0"
  s.summary                 = "ViperMcFlurryX - Support for VIPER concept on iOS"

  s.homepage                = "https://github.com/ladeiko/ViperMcFlurryX"
  s.license                 = 'MIT'
  s.authors                 = { "Siarhei Ladzeika" => "sergey.ladeiko@gmail.com",
                                "Cheslau Bachko" => "cheslau.bachko@gmail.com" }
  
  s.source                  = { :git => "https://github.com/ladeiko/ViperMcFlurryX.git", :tag => "swift_#{s.version.to_s}" }
  
  s.ios.deployment_target   = '10.0'
  s.swift_versions          = ['4.2', '5.0', '5.1', '5.2']
  s.requires_arc            = true
  s.static_framework        = true
  s.default_subspec         = 'Core'

  s.subspec 'Core' do |core|
    core.source_files            = "Source/ViperMcFlurry_Swift/**/*.{Swift}"
    core.dependency              'ViperMcFlurryX', '>= 3.1.0'
  end

  s.subspec 'EmbeddableModule' do |embeddable_module|
    embeddable_module.source_files = "Source/EmbeddableModule/**/*.{Swift}"
    embeddable_module.dependency 'ViperMcFlurryX_Swift/Core'
  end

end
