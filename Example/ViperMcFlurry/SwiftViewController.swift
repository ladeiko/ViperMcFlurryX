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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
