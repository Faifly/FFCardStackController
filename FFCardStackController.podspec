Pod::Spec.new do |spec|
spec.name = "FFCardStackController"
spec.version = "1.3.1"
spec.summary = "Cards management view controller"
spec.homepage = "https://github.com/Faifly/FFCardStackController"
spec.license = { type: 'MIT', file: 'LICENSE' }
spec.authors = { "Artem Kalmykov" => 'ar.kalmykov@gmail.com' }

spec.platform = :ios, "8.0"
spec.requires_arc = true
spec.source = { git: "https://github.com/Faifly/FFCardStackController"}
spec.source_files = "FFCardStackController/FFCardStackController/*.{h,swift}"

end
