import Foundation

@MainActor
public protocol ViperModuleInput: AnyObject {
    func setModuleOutput(_ moduleOutput: ViperModuleOutput)
    func moduleDidSkipOnDismiss()
}

@MainActor
extension ViperModuleInput {
    public func setModuleOutput(_ moduleOutput: ViperModuleOutput) { }
    public func moduleDidSkipOnDismiss() { }
}
