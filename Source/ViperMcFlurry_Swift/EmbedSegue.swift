//
//  EmbedSegue.swift
//  ViperMcFlurrySwift
//
//  Authors: Cheslau Bachko, Siarhei Ladzeika.
//

import Foundation

public class EmbedSegue: UIStoryboardSegue {
    public override func perform() {
        guard let identifier = identifier else { return }
        let parentViewController = source
        let embedViewController = destination
        
        guard let containerViewProvider = parentViewController as? EmbedSegueContainerViewProvider,
              let containerView = containerViewProvider.containerViewForSegue(identifier),
              let moduleView = embedViewController.view else { return }
        
        parentViewController.addChild(embedViewController)
        containerView.addSubview(moduleView)
        embedViewController.didMove(toParent: parentViewController)

        moduleView.translatesAutoresizingMaskIntoConstraints = false

        let top = NSLayoutConstraint(item: moduleView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 0)
        let bot = NSLayoutConstraint(item: moduleView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0)
        let left = NSLayoutConstraint(item: moduleView, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: moduleView, attribute: .right, relatedBy: .equal, toItem: containerView, attribute: .right, multiplier: 1, constant: 0)

        containerView.addConstraints([top, bot, left, right])
    }
}
