//
//  ModeController.swift
//  Long
//
//  Created by Matteo Carnelos on 12/05/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import UIKit

class ModeController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func downPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
