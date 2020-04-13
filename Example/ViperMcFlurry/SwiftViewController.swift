//
//  SwiftViewController.swift
//  ViperMcFlurry_Example
//
//  Created by Sergey Ladeiko on 3/3/20.
//  Copyright © 2020 Egor Tolstoy. All rights reserved.
//

import UIKit
import ViperMcFlurryX_Swift

class SwiftViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func show(_ sender: Any) {
        openModuleUsingFactory(RootModuleConfigurator()) { (source, destination) in
            (source as! UIViewController).present(destination as! UIViewController, animated: true, completion: nil)
        }.thenChainUsingBlock { (moduleInput) -> ViperModuleOutput? in
            return nil
        }
    }

    @IBAction func showColors() {
        openModuleUsingFactory(ColorsModuleConfigurator()) { (source, destination) in
            (source as! UIViewController).present(destination as! UIViewController, animated: true, completion: nil)
        }.thenChainUsingBlock { (moduleInput) -> ViperModuleOutput? in
            (moduleInput as! ColorsModuleInput).configure(withColors: [.red, .gray, .green, .blue, .cyan, .brown, .magenta, .orange, .purple])
            return nil
        }
    }
}
