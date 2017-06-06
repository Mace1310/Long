//
//  OptionsController.swift
//  Long
//
//  Created by Matteo Carnelos on 19/03/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import UIKit
import CoreBluetooth

class OptionsController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var NameField: UITextField!
    @IBOutlet weak var ServiceField: UITextField!
    @IBOutlet weak var CharacteristicField: UITextField!
    
    let Values = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        NameField.delegate = self
        ServiceField.delegate = self
        CharacteristicField.delegate = self
        NameField.text = Values.string(forKey: "BLEName")
        ServiceField.text = Values.string(forKey: "ServiceUUID")
        CharacteristicField.text = Values.string(forKey: "CharacteristicUUID")
    }
 
    @IBAction func downPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func resetPressed(sender: UIButton) {
        NameField.text = "HMSoft"
        Values.set("HMSoft", forKey: "BLEName")
        ServiceField.text = "FFE0"
        Values.set("FFE0", forKey: "ServiceUUID")
        CharacteristicField.text = "FFE1"
        Values.set("FFE1", forKey: "CharacteristicUUID")
    }
    
    @IBAction func nameFieldStartedEditing(sender: UITextField) {
        NameField.placeholder = NameField.text
    }
    
    @IBAction func serviceFieldStartedEditing(sender: UITextField) {
        ServiceField.placeholder = ServiceField.text
    }
    
    @IBAction func characteristicFieldStartedEditing(sender: UITextField) {
        CharacteristicField.placeholder = CharacteristicField.text
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text == "" {
            textField.text = textField.placeholder
        }
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func nameFieldFinishedEditing(sender: UITextField) {
        if NameField.text == "" {
            NameField.text = NameField.placeholder
        }
        else {
            Values.set(NameField.text, forKey: "BLEName")
        }
    }
    
    @IBAction func serviceFieldFinishedEditing(sender: UITextField) {
        ServiceField.text = ServiceField.text?.uppercased()
        if stringIsCBUUID(string: ServiceField.text!) {
            Values.set(ServiceField.text, forKey: "ServiceUUID")
        }
        else {
            let alert = UIAlertController(title: "CBUUID Error", message: "The UUID is not valid.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            ServiceField.text = ServiceField.placeholder
        }
    }
    
    @IBAction func characteristicFieldFinishedEditing(sender: UITextField) {
        CharacteristicField.text = CharacteristicField.text?.uppercased()
        if stringIsCBUUID(string: CharacteristicField.text!) {
            Values.set(CharacteristicField.text, forKey: "CharacteristicUUID")
        }
        else {
            let alert = UIAlertController(title: "CBUUID Error", message: "The UUID is not valid.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            CharacteristicField.text = CharacteristicField.placeholder
        }
    }
    
    func stringIsCBUUID(string: String) -> Bool {
        if string == "" {
            return false
        }
        if string.characters.count != 4 {
            return false
        }
        if string.contains(" ") {
            return false
        }
        let AvailableCharacters = "1234567890ABCDEF"
        for c in string.unicodeScalars {
            if !AvailableCharacters.contains(String(c)) {
                return false
            }
        }
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
