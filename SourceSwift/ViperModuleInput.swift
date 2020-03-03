import Foundation

public protocol ViperModuleInput: class {
    func setModuleOutput(_ moduleOutput: ViperModuleOutput)
    func moduleDidSkipOnDismiss()
}

extension ViperModuleInput {
    public func setModuleOutput(_ moduleOutput: ViperModuleOutput) { }
    public func moduleDidSkipOnDismiss() { }
}
