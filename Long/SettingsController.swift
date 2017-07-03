//
//  SettingsController.swift
//  Long
//
//  Created by Matteo Carnelos on 03/07/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import UIKit

class SettingsController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backPressed(_ sender: UIButton) {
        self.navigationController!.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }

}
