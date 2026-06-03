// swift-tools-version:5.5
import PackageDescription

// ViperMcFlurryX — Swift Package Manager support.
//
// The package mirrors the CocoaPods layout:
//   • ViperMcFlurryX               — Objective-C core (Source/ViperMcFlurry)
//   • ViperMcFlurryX_Swift         — Swift API (Source/ViperMcFlurry_Swift)
//   • ViperMcFlurryXEmbeddableModule — Swift embeddable-module helper
//
// The Swift API does not import the Objective-C module at compile time; it
// drives it at runtime through an Objective-C category that swizzles
// `prepareForSegue:` in `+load` and exposes `swift_bridge_*` selectors. Because
// those symbols are only referenced at runtime (via NSSelectorFromString), the
// linker can drop the category's object file from a static library and the
// swizzle would never install.
//
// IMPORTANT: consuming apps must add `-ObjC` to "Other Linker Flags"
// (OTHER_LDFLAGS) so the Objective-C category is force-loaded. Without it,
// runtime APIs such as closeCurrentModule / openModuleUsingSegue will fail.
//
// The CocoaPods `ViperMcFlurrySwiftFix` dependency is intentionally omitted: it
// is a CocoaPods-only shim and is not referenced by the library sources (the
// Swift `moduleInputInterface` already performs the equivalent `output`
// reflection fallback).
let package = Package(
    name: "ViperMcFlurryX",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "ViperMcFlurryX", targets: ["ViperMcFlurryX"]),
        .library(name: "ViperMcFlurryX_Swift", targets: ["ViperMcFlurryX_Swift"]),
        .library(name: "ViperMcFlurryXEmbeddableModule", targets: ["ViperMcFlurryXEmbeddableModule"]),
    ],
    targets: [
        .target(
            name: "ViperMcFlurryX",
            path: "Source/ViperMcFlurry",
            publicHeadersPath: "."
        ),
        .target(
            name: "ViperMcFlurryX_Swift",
            dependencies: ["ViperMcFlurryX"],
            path: "Source/ViperMcFlurry_Swift"
        ),
        .target(
            name: "ViperMcFlurryXEmbeddableModule",
            dependencies: ["ViperMcFlurryX_Swift"],
            path: "Source/EmbeddableModule"
        ),
    ]
)
