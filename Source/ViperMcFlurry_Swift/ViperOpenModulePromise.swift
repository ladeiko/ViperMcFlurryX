import Foundation

public class ViperOpenModulePromise {
    typealias PostLinkActionBlock = () -> Void
    typealias PostChainActionBlock = () -> Void
    /**
    This module is used to link modules one to another. ModuleInput is typically presenter of module.
    Block can be used to return module output.
    */
    public typealias ViperModuleLinkBlock = (_ moduleInput: ViperModuleInput) -> ViperModuleOutput?

    var moduleInput: ViperModuleInput? {
        didSet {
            self.tryPerformLink()
        }
    }
    var postLinkActionBlock: PostLinkActionBlock?
    var postChainActionBlock: PostChainActionBlock?

    private var linkBlock: ViperModuleLinkBlock?

    public func thenChainUsingBlock(_ linkBlock: @escaping ViperModuleLinkBlock) {
        self.linkBlock = linkBlock
        self.tryPerformLink()
        if let postChainActionBlock = self.postChainActionBlock {
            postChainActionBlock()
            self.postChainActionBlock = nil
        }
    }


    private func tryPerformLink() {
        if self.linkBlock != nil && self.moduleInput != nil {
            self.performLink()
        }
    }

    private func performLink() {
        guard let linkBlock = self.linkBlock,
            let moduleInput = self.moduleInput else { return }
        if let moduleOutput = linkBlock(moduleInput) {
            moduleInput.setModuleOutput(moduleOutput)
        }

        if let postLinkActionBlock = self.postLinkActionBlock {
            postLinkActionBlock()
        }
    }
}
