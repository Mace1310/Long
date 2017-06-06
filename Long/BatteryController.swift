//
//  BatteryController.swift
//  Long
//
//  Created by Matteo Carnelos on 04/05/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import UIKit

class BatteryController: UIViewController, TransmissionsDelegate {
    
    let TransmissionsManager = Transmissions.T
    
    @IBOutlet weak var BatteryPercentageLabel: UILabel!
    @IBOutlet weak var B1C1Label: UILabel!
    @IBOutlet weak var B1C2Label: UILabel!
    @IBOutlet weak var B1C3Label: UILabel!
    @IBOutlet weak var B1C4Label: UILabel!
    @IBOutlet weak var B2C1Label: UILabel!
    @IBOutlet weak var B2C2Label: UILabel!
    @IBOutlet weak var B2C3Label: UILabel!
    @IBOutlet weak var B2C4Label: UILabel!
    @IBOutlet weak var B1C1Bar: UIProgressView!
    @IBOutlet weak var B1C2Bar: UIProgressView!
    @IBOutlet weak var B1C3Bar: UIProgressView!
    @IBOutlet weak var B1C4Bar: UIProgressView!
    @IBOutlet weak var B2C1Bar: UIProgressView!
    @IBOutlet weak var B2C2Bar: UIProgressView!
    @IBOutlet weak var B2C3Bar: UIProgressView!
    @IBOutlet weak var B2C4Bar: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        TransmissionsManager.delegate = self
        TransmissionsManager.requestBatteryPercentage()
        TransmissionsManager.requestCellVoltage(0x01)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateValues), userInfo: nil, repeats: true);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateValues() {
        TransmissionsManager.requestBatteryPercentage()
        TransmissionsManager.requestCellVoltage(0x01)
    }
    
    func RPMResponseReceived(_ RPM1: UInt16, _ RPM2: UInt16) {}
    func boardNameResponseRecieved(_ BoardName: String) {}
    func systemStatusResponseRecieved(_ args: UInt8) {}
    
    func cellVoltageToProgress(_ cellVoltage: Float32!) -> Float {
        return (cellVoltage - 3.27) / (4.20 - 3.27)
    }
    
    func cellVoltagesResponseRecieved(_ Battery1: Transmissions.LipoBattery, _ Battery2: Transmissions.LipoBattery) {
        B1C1Label.text = String(format: "%.2f V", Battery1.cell1)
        B1C2Label.text = String(format: "%.2f V", Battery1.cell2)
        B1C3Label.text = String(format: "%.2f V", Battery1.cell3)
        B1C4Label.text = String(format: "%.2f V", Battery1.cell4)
        B2C1Label.text = String(format: "%.2f V", Battery2.cell1)
        B2C2Label.text = String(format: "%.2f V", Battery2.cell2)
        B2C3Label.text = String(format: "%.2f V", Battery2.cell3)
        B2C4Label.text = String(format: "%.2f V", Battery2.cell4)
        B1C1Bar.setProgress(cellVoltageToProgress(Battery1.cell1), animated: true)
        B1C2Bar.setProgress(cellVoltageToProgress(Battery1.cell2), animated: true)
        B1C3Bar.setProgress(cellVoltageToProgress(Battery1.cell3), animated: true)
        B1C4Bar.setProgress(cellVoltageToProgress(Battery1.cell4), animated: true)
        B2C1Bar.setProgress(cellVoltageToProgress(Battery2.cell1), animated: true)
        B2C2Bar.setProgress(cellVoltageToProgress(Battery2.cell2), animated: true)
        B2C3Bar.setProgress(cellVoltageToProgress(Battery2.cell3), animated: true)
        B2C4Bar.setProgress(cellVoltageToProgress(Battery2.cell4), animated: true)
    }
    
    func batteryPercentageResponseRecieved(_ BatteryPercentage: UInt8) {
        if BatteryPercentage == 101 {
            BatteryPercentageLabel.text = "ERROR"
        }
        else {
            BatteryPercentageLabel.text = "\(BatteryPercentage) %"
        }
    }

    
    @IBAction func downPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
