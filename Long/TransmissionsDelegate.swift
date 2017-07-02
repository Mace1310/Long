//
//  TransmissionsDelegate.swift
//  Long
//
//  Created by Matteo Carnelos on 04/05/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import Foundation

protocol TransmissionsDelegate: class {
    
    func RPMResponseReceived(_ RPM1: UInt16, _ RPM2: UInt16)
    
    func cellVoltagesResponseRecieved(_ Battery1: Transmissions.LipoBattery, _ Battery2: Transmissions.LipoBattery)
    
    func batteryPercentageResponseRecieved(_ BatteryPercentage: UInt8)
    
    func boardNameResponseRecieved(_ BoardName: String)
    
    func systemStatusResponseRecieved(_ SystemStatus: UInt8)
    
    func modeCodeResponseRecieved(_ ModeCode: UInt8)
    
    func currentResponseRecieved(_ Current1: Float32, _ Current2: Float32)
}
