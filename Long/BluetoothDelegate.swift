//
//  BluetoothDelegate.swift
//  Long
//
//  Created by Matteo Carnelos on 19/04/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothDelegate: class {
    
    func stateUpdated(state: CBManagerState)
    
    func connectedToPeripheral()
    
    func peripheralDisconnected()
    
}
