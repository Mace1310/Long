//
//  LongControllerOLD.swift
//  Long
//
//  Created by Matteo Carnelos on 16/03/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import UIKit
import CoreBluetooth

class LongControllerOLD: UIViewController, UITextFieldDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var BoardNameField: UITextField!
    @IBOutlet weak var EditButton: UIButton!
    @IBOutlet weak var StateButton: UIButton!
    @IBOutlet weak var SearchingIcon: UIImageView!
    @IBOutlet weak var BatteryProgressBar: KDCircularProgress!
    @IBOutlet weak var BatteryPercentageButton: UIButton!
    @IBOutlet weak var ModeSelectedButton: UIButton!
    @IBOutlet weak var GOButton: UIButton!
    @IBOutlet weak var ForwardIcon: UIImageView!
    @IBOutlet weak var SETTINGSButton: UIButton!
    
    var Manager: CBCentralManager!
    var Board: CBPeripheral!
    var DEVICE_NAME: String!
    var DEVICE_SERVICE_UUID: CBUUID!
    var DEVICE_CHARACTERISTIC_UUID: CBUUID!
    var DEVICE_CHARACTERISTIC: CBCharacteristic!
    
    let Values = UserDefaults.standard
    
    var ConnectedToPeripheral = false
    var DisconnectedByUser = false
    var Discovering = false

    override func viewDidLoad() {
        super.viewDidLoad()
        BoardNameField.delegate = self
        Manager = CBCentralManager(delegate: self, queue: nil)
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateValues), userInfo: nil, repeats: true);
        startAnimateSearchingIcon()
        startAnimateGoArrow()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        let Name = Values.string(forKey: "BLEName")
        let ServiceUUID = CBUUID(string: Values.string(forKey: "ServiceUUID")!)
        let CharacteristicUUID = CBUUID(string: Values.string(forKey: "CharacteristicUUID")!)
        if ConnectedToPeripheral || Discovering {
            if Name != DEVICE_NAME || ServiceUUID != DEVICE_SERVICE_UUID || CharacteristicUUID != DEVICE_CHARACTERISTIC_UUID {
                Manager.cancelPeripheralConnection(Board)
            }
        }
        else if Manager.isScanning {
            if Name != DEVICE_NAME || ServiceUUID != DEVICE_SERVICE_UUID || CharacteristicUUID != DEVICE_CHARACTERISTIC_UUID {
                Manager.stopScan()
                scanForPeripherals()
            }
        }
    }
    
    @IBAction func stateButtonPressed(sender: UIButton) {
        if Manager.state == .poweredOff {
            let alert = UIAlertController(title: "Bluetooth disabled", message: "Turn on the bluetooth in order to connect to the board.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else if Manager.state == .unsupported {
            let alert = UIAlertController(title: "Error", message: "Bluetooth 4.0 is not supported by the device.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else if Manager.state == .poweredOn {
            if ConnectedToPeripheral {
                let alert = UIAlertController(title: "Connected", message: "Correctly connected to peripheral.\nName: \(DEVICE_NAME!)\nService UUID: \(DEVICE_SERVICE_UUID!)\nCharacteristic UUID: \(DEVICE_CHARACTERISTIC_UUID!)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Disconnect", style: .destructive, handler: { action in
                    switch action.style{
                    case .destructive:
                        self.Manager.cancelPeripheralConnection(self.Board)
                        self.DisconnectedByUser = true
                        self.setStateIcon(image: #imageLiteral(resourceName: "Searching"))
                        break
                    default: break
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                scanForPeripherals()
            }
        }
        else {
            let alert = UIAlertController(title: "Error", message: "Unknown error.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        disableControls()
        switch(Manager.state) {
        case .poweredOff:
            setStateIcon(image: #imageLiteral(resourceName: "Offline"))
            break
        case .poweredOn:
            scanForPeripherals()
            break
        default:
            setStateIcon(image: #imageLiteral(resourceName: "Error"))
            break
        }
    }
    
    func scanForPeripherals() {
        DEVICE_SERVICE_UUID = CBUUID(string: Values.string(forKey: "ServiceUUID")!)
        DEVICE_NAME = Values.string(forKey: "BLEName")
        DEVICE_CHARACTERISTIC_UUID = CBUUID(string: Values.string(forKey: "CharacteristicUUID")!)
        setStateIcon(image: #imageLiteral(resourceName: "Searching"), animating: true)
        Manager.scanForPeripherals(withServices: [DEVICE_SERVICE_UUID], options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == DEVICE_NAME {
            Board = peripheral
            Board.delegate = self
            Manager.stopScan()
            Manager.connect(Board, options: nil)
        }
        else {
            scanForPeripherals()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        Discovering = true
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == DEVICE_SERVICE_UUID {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Discovering = false
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == DEVICE_CHARACTERISTIC_UUID {
                    DEVICE_CHARACTERISTIC = characteristic
                    ConnectedToPeripheral = true
                    setStateIcon(image: #imageLiteral(resourceName: "NoConnection"))
                    enableControls()
                }
            }
        }
    }
    
    @objc func updateValues() {
        if ConnectedToPeripheral {
            Board.readRSSI()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        let RSSIValue = Int(truncating: RSSI)
        if RSSIValue >= -55 {
            setStateIcon(image: #imageLiteral(resourceName: "HighConnection"))
        }
        else if RSSIValue < -55 && RSSIValue >= -75 {
            setStateIcon(image: #imageLiteral(resourceName: "MediumConnection"))
        }
        else if RSSIValue < -75 && RSSIValue >= -85 {
            setStateIcon(image: #imageLiteral(resourceName: "LowConnection"))
        }
        else if RSSIValue < -85 {
            setStateIcon(image: #imageLiteral(resourceName: "NoConnection"))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        ConnectedToPeripheral = false
        disableControls()
        if DisconnectedByUser == false {
            scanForPeripherals()
        }
        else {
            DisconnectedByUser = false
        }
    }
    
    func disableControls() {
        EditButton.isEnabled = false
        BoardNameField.text = "MY BOARD"
        BatteryPercentageButton.isEnabled = false
        BatteryPercentageButton.setTitle("....", for: .normal)
        ModeSelectedButton.isEnabled = false
        ModeSelectedButton.setTitle("....", for: .normal)
        GOButton.isEnabled = false
        ForwardIcon.isHidden = true
        SETTINGSButton.isEnabled = false
    }
    
    func enableControls() {
        EditButton.isEnabled = true
        BatteryPercentageButton.isEnabled = true
        ModeSelectedButton.isEnabled = true
        GOButton.isEnabled = true
        ForwardIcon.isHidden = false
        SETTINGSButton.isEnabled = true
    }
    
    func setStateIcon(image: UIImage, animating: Bool = false) {
        if image == #imageLiteral(resourceName: "Searching") && animating {
            StateButton.isHidden = true
            StateButton.isEnabled = false
            SearchingIcon.isHidden = false
        }
        else {
            if image == #imageLiteral(resourceName: "HighConnection") {
                StateButton.tintColor = UIColor(red:0.15, green:0.68, blue:0.38, alpha:1.0)
            }
            else if image == #imageLiteral(resourceName: "MediumConnection") {
                StateButton.tintColor = UIColor(red:0.90, green:0.49, blue:0.13, alpha:1.0)
            }
            else if image == #imageLiteral(resourceName: "Searching") {
                StateButton.tintColor = UIColor.black
            }
            else {
                StateButton.tintColor = UIColor(red:0.75, green:0.22, blue:0.17, alpha:1.0)
            }
            StateButton.setImage(image, for: .normal)
            StateButton.isHidden = false
            StateButton.isEnabled = true
            SearchingIcon.isHidden = true
        }
    }

    @IBAction func editPressed(sender: UIButton) {
        if BoardNameField.isEnabled == false {
            BoardNameField.placeholder = BoardNameField.text
            BoardNameField.isEnabled = true
            EditButton.setImage(#imageLiteral(resourceName: "Done"), for: .normal)
            BoardNameField.becomeFirstResponder()
        }
        else {
            var no_space = false
            for c in BoardNameField.text!.characters {
                if c != " " {
                    no_space = true
                }
            }
            if BoardNameField.text == "" || no_space == false {
                BoardNameField.text = BoardNameField.placeholder
            }
            BoardNameField.text = BoardNameField.text?.uppercased()
            BoardNameField.isEnabled = false
            EditButton.setImage(#imageLiteral(resourceName: "Edit"), for: .normal)
            BoardNameField.resignFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var no_space = false
        for c in BoardNameField.text!.characters {
            if c != " " {
                no_space = true
            }
        }
        if BoardNameField.text == "" || no_space == false {
            BoardNameField.text = BoardNameField.placeholder
        }
        BoardNameField.text = BoardNameField.text?.uppercased()
        BoardNameField.isEnabled = false
        EditButton.setImage(#imageLiteral(resourceName: "Edit"), for: .normal)
        BoardNameField.resignFirstResponder()
        return true
    }
    
    func startAnimateGoArrow() {
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseInOut, animations: {
            self.ForwardIcon.alpha = 0
            self.ForwardIcon.center.x = 320
        }) { (finished) in
            self.ForwardIcon.center.x = 266
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
                self.ForwardIcon.alpha = 1
            }, completion: { (finished) in
                self.startAnimateGoArrow()
            })
        }
    }
    
    func startAnimateSearchingIcon() {
        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations: {
            self.SearchingIcon.transform = self.SearchingIcon.transform.rotated(by: CGFloat(Double.pi))
        }, completion: { (finished) in
            self.startAnimateSearchingIcon()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
