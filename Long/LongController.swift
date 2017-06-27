//
//  LongController.swift
//  Long
//
//  Created by Matteo Carnelos on 16/03/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import UIKit
import CoreBluetooth

class LongController: UIViewController, UITextFieldDelegate, BluetoothDelegate, TransmissionsDelegate {
    
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
    @IBOutlet weak var SystemStatusLabel: UILabel!
    
    let BluetoothManager = Bluetooth.CB
    let TransmissionsManager = Transmissions.T
    
    var DisconnectedByUser = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        BoardNameField.delegate = self
        BluetoothManager.initManager()
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateValues), userInfo: nil, repeats: true);
        
        startAnimateSearchingIcon()
        startAnimateGoArrow()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        BluetoothManager.delegate = self
        TransmissionsManager.delegate = self
        TransmissionsManager.requestModeCode()
        if BluetoothManager.optionsChanged() {
            if BluetoothManager.isConnected || BluetoothManager.isDiscovering {
                BluetoothManager.disconnect()
            }
            else if BluetoothManager.isScanning {
                BluetoothManager.stopScan()
                scanForPeripherals()
            }
        }
    }
    
    func RPMResponseReceived(_ RPM1: UInt16, _ RPM2: UInt16) {}
    func cellVoltagesResponseRecieved(_ Battery1: Transmissions.LipoBattery, _ Battery2: Transmissions.LipoBattery) {}

    func modeCodeResponseRecieved(_ args: UInt8) {
        switch args {
        case 0x00:
            ModeSelectedButton.setTitle("NORM", for: .normal)
            break
        case 0x01:
            ModeSelectedButton.setTitle("BEG", for: .normal)
            break
        case 0x02:
            ModeSelectedButton.setTitle("SPORT", for: .normal)
            break
        case 0x03:
            ModeSelectedButton.setTitle("ECO", for: .normal)
            break
        case 0x04:
            ModeSelectedButton.setTitle("AUTO", for: .normal)
            break
        case 0x05:
            ModeSelectedButton.setTitle("PROG", for: .normal)
            break
        default:
            break
        }
    }
    
    func systemStatusResponseRecieved(_ args: UInt8) {
        switch args {
        case 0x00:
            SystemStatusLabel.text = "READY TO GO"
            break
        case 0x01:
            SystemStatusLabel.text = "EEPROM ERROR"
            break
        case 0x02:
            SystemStatusLabel.text = "CELL ERROR"
            break
        case 0x03:
            SystemStatusLabel.text = "BATTERY ERROR"
            break
        case 0x04:
            SystemStatusLabel.text = "WARMING UP..."
        default:
            break
        }
    }
    
    func batteryPercentageResponseRecieved(_ BatteryPercentage: UInt8) {
        if BatteryPercentage == 101 {
            BatteryPercentageButton.setTitle("ERROR", for: .normal)
            BatteryProgressBar.animate(toAngle: 0, duration: 1, completion: nil)
        }
        else {
            BatteryPercentageButton.setTitle("\(BatteryPercentage) %", for: .normal)
            BatteryProgressBar.animate(toAngle: Double(BatteryPercentage) * 2.7, duration: 1, completion: nil)
        }
    }
    
    func boardNameResponseRecieved(_ BoardName: String) {
        if BoardNameField.isEditing == false {
            BoardNameField.text = BoardName
        }
    }
    
    @IBAction func stateButtonPressed(sender: UIButton) {
        let ManagerState = BluetoothManager.getManagerState()
        switch(ManagerState) {
        case .poweredOff:
            createAlertWithOk(title: "Bluetooth disabled", message: "Turn on the bluetooth in order to connect to the board.")
            break
        case .poweredOn:
            if BluetoothManager.isConnected {
                createAlertWithOk(title: "Connected", message: "Correctly connected to the peripheral.\nName: \(BluetoothManager.DEVICE_NAME!)\nService UUID: \(BluetoothManager.DEVICE_SERVICE_UUID!)\nCharacteristic UUID: \(BluetoothManager.DEVICE_CHARACTERISTIC_UUID!)", disconnectButton: true)
            }
            else {
                scanForPeripherals()
            }
            break
        case .unsupported:
            createAlertWithOk(title: "Error", message: "Bluetooth 4.0 is not supported by the device.")
            break
        default:
            createAlertWithOk(title: "Error", message: "Unknown error.")
        }
    }
    
    func createAlertWithOk(title: String, message: String, disconnectButton: Bool = false) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        if disconnectButton {
            let ExtraAction = UIAlertAction(title: "Disconnect", style: .destructive, handler: { action in
                switch action.style{
                case .destructive:
                    self.BluetoothManager.disconnect()
                    self.DisconnectedByUser = true
                    self.setStateIcon(image: #imageLiteral(resourceName: "Searching"))
                    break
                default: break
                }
            })
            alert.addAction(ExtraAction)
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func stateUpdated(state: CBManagerState) {
        disableControls()
        switch(state) {
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
        BluetoothManager.scan()
        setStateIcon(image: #imageLiteral(resourceName: "Searching"), animating: true)
    }
    
    func connectedToPeripheral() {
        setStateIcon(image: #imageLiteral(resourceName: "NoConnection"))
        enableControls()
    }
    
    func updateValues() {
        if BluetoothManager.isConnected {
            updateSignalStrength(strength: BluetoothManager.SignalStrength)
            TransmissionsManager.requestBoardName()
            TransmissionsManager.requestBatteryPercentage()
            TransmissionsManager.requestSystemStatus()
            TransmissionsManager.requestModeCode()
        }
    }
    
    func updateSignalStrength(strength: Int) {
        if strength >= -55 {
            setStateIcon(image: #imageLiteral(resourceName: "HighConnection"))
        }
        else if strength < -55 && strength >= -75 {
            setStateIcon(image: #imageLiteral(resourceName: "MediumConnection"))
        }
        else if strength < -75 && strength >= -85 {
            setStateIcon(image: #imageLiteral(resourceName: "LowConnection"))
        }
        else if strength < -85 {
            setStateIcon(image: #imageLiteral(resourceName: "NoConnection"))
        }
    }
    
    func peripheralDisconnected() {
        disableControls()
        if DisconnectedByUser {
            DisconnectedByUser = false
        }
        else {
            scanForPeripherals()
        }
    }
    
    func disableControls() {
        EditButton.isEnabled = false
        BoardNameField.text = "MY BOARD"
        BatteryPercentageButton.isEnabled = false
        BatteryPercentageButton.setTitle("....", for: .normal)
        BatteryProgressBar.animate(toAngle: 270, duration: 1, completion: nil)
        ModeSelectedButton.isEnabled = false
        ModeSelectedButton.setTitle("....", for: .normal)
        GOButton.isEnabled = true                   //RIMETTERE FALSE
        ForwardIcon.isHidden = true
        SETTINGSButton.isEnabled = false
        SystemStatusLabel.text = "DISCONNECTED"
    }
    
    func enableControls() {
        EditButton.isEnabled = true
        BatteryPercentageButton.isEnabled = true
        ModeSelectedButton.isEnabled = true
        GOButton.isEnabled = true
        ForwardIcon.isHidden = false
        SETTINGSButton.isEnabled = true
        SystemStatusLabel.text = "CHECKING..."
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
            if BoardNameField.text == "" || no_space == false || (BoardNameField.text?.characters.count)! > 20 {
                BoardNameField.text = BoardNameField.placeholder
            }
            BoardNameField.text = BoardNameField.text?.uppercased()
            BoardNameField.isEnabled = false
            EditButton.setImage(#imageLiteral(resourceName: "Edit"), for: .normal)
            BoardNameField.resignFirstResponder()
            TransmissionsManager.setBoardName(BoardNameField.text!)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var no_space = false
        for c in BoardNameField.text!.characters {
            if c != " " {
                no_space = true
            }
        }
        if BoardNameField.text == "" || no_space == false || (BoardNameField.text?.characters.count)! > 20 {
            BoardNameField.text = BoardNameField.placeholder
        }
        BoardNameField.text = BoardNameField.text?.uppercased()
        BoardNameField.isEnabled = false
        EditButton.setImage(#imageLiteral(resourceName: "Edit"), for: .normal)
        BoardNameField.resignFirstResponder()
        TransmissionsManager.setBoardName(BoardNameField.text!)
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
