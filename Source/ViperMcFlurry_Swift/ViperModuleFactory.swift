
@MainActor
public protocol ViperModuleFactory {
    func instantiateModuleTransitionHandler() -> ViperModuleTransitionHandler
}
