//
//  EmbedSegueViewContainerProvider.swift
//  ViperMcFlurrySwift
//
//  Authors: Cheslau Bachko, Siarhei Ladzeika.
//

import Foundation

public protocol EmbedSegueContainerViewProvider {
    func containerViewForSegue(_ identifier: String) -> UIView?
}
