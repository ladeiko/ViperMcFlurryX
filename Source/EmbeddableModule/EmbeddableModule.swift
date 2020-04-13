import Foundation

public typealias EmbeddableModuleAttacher = (_ toView: UIView) -> Void
public typealias EmbeddableModuleDetacher = () -> Void

public protocol EmbeddableModuleView {
    var attacher: EmbeddableModuleAttacher { get }
    var detacher: EmbeddableModuleDetacher { get }
}

public struct EmbeddableModule<T> : EmbeddableModuleView {
    public let module: T
    public let attacher: EmbeddableModuleAttacher
    public let detacher: EmbeddableModuleDetacher
    
    public init(module: T, attacher: @escaping (UIView) -> Void, detacher: @escaping () -> Void) {
        self.module = module
        self.attacher = attacher
        self.detacher = detacher
    }
}

