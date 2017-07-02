//
//  Transmissions.swift
//  Long
//
//  Created by Matteo Carnelos on 04/05/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import Foundation

class Transmissions: NSObject {
    
    static let T = Transmissions()
    let BluetoothManager = Bluetooth.CB
    
    weak var delegate: TransmissionsDelegate?
    
    struct LipoBattery {
        var cell1: Float32!
        var cell2: Float32!
        var cell3: Float32!
        var cell4: Float32!
    }
    
    var Battery1 = LipoBattery(cell1: 0, cell2: 0, cell3: 0, cell4: 0)
    var Battery2 = LipoBattery(cell1: 0, cell2: 0, cell3: 0, cell4: 0)
    
    private override init() { }
    
    func currentResponse(_ args: [UInt8]) {
        let Current1_CHAR = [args[0], args[1], args[2], args[3]]
        let Current2_CHAR = [args[4], args[5], args[6], args[7]]
        let Current1: Float32! = UnsafePointer(Current1_CHAR).withMemoryRebound(to: Float32.self, capacity: 1) { $0.pointee }
        let Current2: Float32! = UnsafePointer(Current2_CHAR).withMemoryRebound(to: Float32.self, capacity: 1) { $0.pointee }
        delegate?.currentResponseRecieved(-Current1, Current2)
    }
    
    func requestCurrent() {
        BluetoothManager.txBuffer[0] = 0x13
        BluetoothManager.txLength = 1
        BluetoothManager.flushTxBuffer()
    }
    
    func emergencyStop() {
        BluetoothManager.txBuffer[0] = 0x03
        BluetoothManager.txLength = 1
        BluetoothManager.flushTxBuffer()
    }
    
    func setModeCode(_ args: UInt8) {
        BluetoothManager.txBuffer[0] = 0x01
        BluetoothManager.txBuffer[1] = args
        BluetoothManager.txLength = 2
        BluetoothManager.flushTxBuffer()
    }
    
    func modeCodeResponse(_ args: UInt8) {
        delegate?.modeCodeResponseRecieved(args)
    }
    
    func requestModeCode() {
        BluetoothManager.txBuffer[0] = 0x16
        BluetoothManager.txLength = 1
        BluetoothManager.flushTxBuffer()
    }
    
    func systemStatusResponse(_ args: UInt8) {
        delegate?.systemStatusResponseRecieved(args)
    }
    
    func requestSystemStatus() {
        BluetoothManager.txBuffer[0] = 0x15
        BluetoothManager.txLength = 1
        BluetoothManager.flushTxBuffer()
    }
    
    func setBoardName(_ args: String) {
        let BoardNameLength = args.characters.count
        let BoardName: [UInt8] = Array(args.utf8)
        BluetoothManager.txBuffer[0] = 0x02
        BluetoothManager.txBuffer[1] = UInt8(BoardNameLength)
        var t = 0
        for i in 2...(1 + BoardName.count) {
            BluetoothManager.txBuffer[i] = BoardName[t]
            t += 1
        }
        BluetoothManager.txBuffer += BoardName
        BluetoothManager.txLength = 2 + BoardName.count
        BluetoothManager.flushTxBuffer()
    }
    
    func requestBoardName() {
        BluetoothManager.txBuffer[0] = 0x14
        BluetoothManager.txLength = 1;
        BluetoothManager.flushTxBuffer()
    }
    
    func boardNameResponse(_ args: [UInt8]) {
        let data = Data(bytes: args);
        if let BoardName = String(data: data, encoding: .utf8) {
            delegate?.boardNameResponseRecieved(BoardName)
        }
        else {
            delegate?.boardNameResponseRecieved("MY BOARD")
        }
    }
    
    func requestBatteryPercentage() {
        BluetoothManager.txBuffer[0] = 0x11
        BluetoothManager.txLength = 1
        BluetoothManager.flushTxBuffer()
    }
    
    func batteryPercentageResponse(_ args: UInt8) {
        delegate?.batteryPercentageResponseRecieved(args)
    }
    
    func requestCellVoltage(_ cellNumber: UInt8) {
        BluetoothManager.txBuffer[0] = 0x12
        BluetoothManager.txBuffer[1] = cellNumber
        BluetoothManager.txLength = 2
        BluetoothManager.flushTxBuffer()
    }
    
    func cellVoltagesResponse(_ args: [UInt8]) {
        let CELL_CHAR = [args[1], args[2], args[3], args[4]]
        let CELL_VOLTAGE: Float32? = UnsafePointer(CELL_CHAR).withMemoryRebound(to: Float32.self, capacity: 1) { $0.pointee }
        switch args[0] {
        case 0x01:
            Battery1.cell1 = CELL_VOLTAGE
            requestCellVoltage(0x02)
            break
        case 0x02:
            Battery1.cell2 = CELL_VOLTAGE
            requestCellVoltage(0x03)
            break
        case 0x03:
            Battery1.cell3 = CELL_VOLTAGE
            requestCellVoltage(0x04)
            break
        case 0x04:
            Battery1.cell4 = CELL_VOLTAGE
            requestCellVoltage(0x05)
            break
        case 0x05:
            Battery2.cell1 = CELL_VOLTAGE
            requestCellVoltage(0x06)
            break
        case 0x06:
            Battery2.cell2 = CELL_VOLTAGE
            requestCellVoltage(0x07)
            break
        case 0x07:
            Battery2.cell3 = CELL_VOLTAGE
            requestCellVoltage(0x08)
            break
        case 0x08:
            Battery2.cell4 = CELL_VOLTAGE
            delegate?.cellVoltagesResponseRecieved(Battery1, Battery2)
            break
        default:
            break
        }
    }
    
    func requestRPM() {
        BluetoothManager.txBuffer[0] = 0x10
        BluetoothManager.txLength = 1
        BluetoothManager.flushTxBuffer()
    }
    
    func RPMResponse(_ args: [UInt8]) {
        let RPM1_CHAR = [args[0], args[1]]
        let RPM2_CHAR = [args[2], args[3]]
        let RPM1 = UnsafePointer(RPM1_CHAR).withMemoryRebound(to: UInt16.self, capacity: 1) { $0.pointee }
        let RPM2 = UnsafePointer(RPM2_CHAR).withMemoryRebound(to: UInt16.self, capacity: 1) { $0.pointee }
        delegate?.RPMResponseReceived(RPM1, RPM2)
    }
    
    func setESC(_ arg: UInt8) {
        BluetoothManager.txBuffer[0] = 0x00
        BluetoothManager.txBuffer[1] = arg
        BluetoothManager.txLength = 2
        BluetoothManager.flushTxBuffer()

    }
    
}
