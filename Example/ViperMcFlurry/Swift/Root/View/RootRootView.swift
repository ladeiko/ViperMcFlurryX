//
//  RootRootView.swift
//  Demo
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2020-present Sergey Ladeiko. All rights reserved.
//

import SwiftUI

protocol RootRootViewProtocol: View {
    var viewState: RootRootViewState { get }
}

struct RootRootView: RootRootViewProtocol {

    weak var delegate: RootRootViewDelegate?

    @ObservedObject var viewState = RootRootViewState()

    var body: some View {
        Group {
            Text("Sample Label \(viewState.sampleValue)")
            Button("Sample Button") {
                self.delegate?.didTapOnSampleButton()
            }
            Button("Close") {
                self.delegate?.didTapOnClose()
            }
        }
    }
}

#if DEBUG
struct RootRootView_Previews: PreviewProvider {
    static var previews: some View {
        RootRootView()
    }
}
#endif
