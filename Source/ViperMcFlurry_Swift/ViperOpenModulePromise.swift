import UIKit

@MainActor
public class ViperOpenModulePromise: NSObject {
    typealias PostLinkActionBlock = () -> Void
    typealias PostChainActionBlock = () -> Void
    /**
     This module is used to link modules one to another. ModuleInput is typically presenter of module.
     Block can be used to return module output.
     */
    public typealias ViperModuleLinkBlock = (_ moduleInput: ViperModuleInput?) -> ViperModuleOutput?
    
    var moduleInput: ViperModuleInput? {
        didSet {
            self.moduleInputWasSet = true
            self.tryPerformLink()
        }
    }

    var postLinkActionBlock: PostLinkActionBlock?
    var postChainActionBlock: PostChainActionBlock?

    private var linkBlock: ViperModuleLinkBlock?
    private var linkBlockWasSet = false
    private var moduleInputWasSet = false

    public func thenChainUsingBlock(_ linkBlock: @escaping ViperModuleLinkBlock) {
        assert(!self.linkBlockWasSet, "thenChainUsingBlock was already called")
        self.linkBlock = linkBlock
        self.linkBlockWasSet = true
        self.tryPerformLink()
        if let postChainActionBlock = self.postChainActionBlock {
            postChainActionBlock()
            self.postChainActionBlock = nil
        }
    }

    private func tryPerformLink() {
        if self.linkBlockWasSet && self.moduleInputWasSet {
            self.performLink()
        }
    }

    private func performLink() {
        guard let linkBlock = self.linkBlock else { return }

        // Matches the Obj-C implementation: the link block is always invoked
        // (with a nil moduleInput when the module has none), and the returned
        // output is wired back only when there is a module input to set it on.
        let moduleOutput = linkBlock(self.moduleInput)
        if let moduleOutput = moduleOutput, let moduleInput = self.moduleInput {
            moduleInput.setModuleOutput(moduleOutput)
        }

        if let postLinkActionBlock = self.postLinkActionBlock {
            postLinkActionBlock()
        }
    }

    // Called from the single Obj-C `prepareForSegue:` swizzle
    // (RamblerViperPrepareForSegueSender) via the `swift_bridge_*` selector
    // convention used elsewhere in this module. `destination` is already
    // nav-controller-unwrapped on the Obj-C side. `prepareForSegue:` runs on
    // the main thread, so this @MainActor call is safe.
    @objc func swift_bridge_prepareForSegue(withDestination destination: UIViewController) {
        self.moduleInput = destination.moduleInputInterface
    }
}
