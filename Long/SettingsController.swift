//
//  SettingsController.swift
//  Long
//
//  Created by Matteo Carnelos on 03/07/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import UIKit
import CoreBluetooth

class SettingsController: UIViewController, BluetoothDelegate, TransmissionsDelegate {
    
    @IBOutlet weak var CellsNumberField: UITextField!
    
    let BluetoothManager = Bluetooth.CB
    let TransmissionsManager = Transmissions.T
    
    var UpdateTimer: Timer!
    var throttleValue = 0
    
    func stateUpdated(state: CBManagerState) {}
    func connectedToPeripheral() {}
    func peripheralDisconnected() {}
    func RPMResponseReceived(_ RPM1: UInt16, _ RPM2: UInt16) {}
    func cellVoltagesResponseRecieved(_ Battery1: Transmissions.LipoBattery, _ Battery2: Transmissions.LipoBattery){}
    func batteryPercentageResponseRecieved(_ BatteryPercentage: UInt8) {}
    func boardNameResponseRecieved(_ BoardName: String) {}
    func systemStatusResponseRecieved(_ SystemStatus: UInt8) {}
    func modeCodeResponseRecieved(_ ModeCode: UInt8) {}
    func currentResponseRecieved(_ Current1: Float32, _ Current2: Float32) {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UpdateTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateValues), userInfo: nil, repeats: true);
    }
    
    func updateValues() {
        if BluetoothManager.isConnected {
            // Get throttle value
            // Update settings and status
        }
        else {
            UpdateTimer.invalidate()
            UpdateTimer = nil
            self.navigationController!.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func stepperPressed(sender: UIStepper) {
        if sender.value == 0 {
            CellsNumberField.text = "Auto"
        }
        else {
            CellsNumberField.text = String(Int(sender.value))
        }
    }
    
    @IBAction func togglePressed(sender: UIButton) {
        if throttleValue == 0 {
            TransmissionsManager.setESC(100);
        }
        else {
            TransmissionsManager.setESC(0);
        }
    }
    
    @IBAction func backPressed(_ sender: UIButton) {
        self.navigationController!.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }

}
