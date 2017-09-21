//
//  Bluetooth.swift
//  Long
//
//  Created by Matteo Carnelos on 19/04/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import CoreBluetooth

class Bluetooth: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let CB = Bluetooth()
    var TransmissionsManager: Transmissions!
    
    weak var delegate: BluetoothDelegate?
    
    var Manager: CBCentralManager!
    var Peripheral: CBPeripheral!
    
    var DEVICE_NAME: String!
    var DEVICE_SERVICE_UUID: CBUUID!
    var DEVICE_CHARACTERISTIC_UUID: CBUUID!
    var DEVICE_CHARACTERISTIC: CBCharacteristic!
    var SignalStrength: Int = 0
    
    let StoredValues = UserDefaults.standard
    
    var isScanning = false
    var isDiscovering = false
    var isConnected = false
    
    var txBuffer: [UInt8] = Array(repeating: 0, count: 100)
    var txLength: Int = 0
    var txBufferDLE: [UInt8] = Array(repeating: 0, count: 100)
    let STX: UInt8 = 0x02
    let ETX: UInt8 = 0x03
    let DLE: UInt8 = 0x10
    let A: UInt8 = 0x41
    let B: UInt8 = 0x42
    let C: UInt8 = 0x43
    
    var rxBuffer: [UInt8] = Array(repeating: 0, count: 100)
    var rxBufferDLE: [UInt8] = Array(repeating: 0, count: 100)
    var rxManagerState = 0
    var rxCounter = 0
    
    private override init() {}
    
    func initManager() {
        Manager = CBCentralManager(delegate: self, queue: nil)
        TransmissionsManager = Transmissions.T
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateValues), userInfo: nil, repeats: true);
        updateOptions()
    }
    
    func updateOptions() {
        if StoredValues.string(forKey: "BLEName") != nil {
            DEVICE_NAME = StoredValues.string(forKey: "BLEName")
        }
        else {
            DEVICE_NAME = "HMSoft"
            StoredValues.set("HMSoft", forKey: "BLEName")
        }
        
        if StoredValues.string(forKey: "ServiceUUID") != nil {
            DEVICE_SERVICE_UUID = CBUUID(string: StoredValues.string(forKey: "ServiceUUID")!)
        }
        else {
            DEVICE_SERVICE_UUID = CBUUID(string: "FFE0")
            StoredValues.set("FFE0", forKey: "ServiceUUID")
        }
        
        if StoredValues.string(forKey: "CharacteristicUUID") != nil {
            DEVICE_CHARACTERISTIC_UUID = CBUUID(string: StoredValues.string(forKey: "CharacteristicUUID")!)
        }
        else {
            DEVICE_CHARACTERISTIC_UUID = CBUUID(string: "FFE1")
            StoredValues.set("FFE1", forKey: "CharacteristicUUID")
        }
    }
    
    func optionsChanged() -> Bool {
        let Name = StoredValues.string(forKey: "BLEName")
        let ServiceUUID = CBUUID(string: StoredValues.string(forKey: "ServiceUUID")!)
        let CharacteristicUUID = CBUUID(string: StoredValues.string(forKey: "CharacteristicUUID")!)
        if Name != DEVICE_NAME || ServiceUUID != DEVICE_SERVICE_UUID || CharacteristicUUID != DEVICE_CHARACTERISTIC_UUID {
            return true
        }
        else {
           return false
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isScanning = false
        isDiscovering = false
        isConnected = false
        delegate?.stateUpdated(state: central.state)
    }
    
    func scan() {
        updateOptions()
        Manager.scanForPeripherals(withServices: [DEVICE_SERVICE_UUID], options: nil)
        isScanning = true
    }
    
    func stopScan() {
        Manager.stopScan()
        isScanning = false
    }
    
    func disconnect() {
        Manager.cancelPeripheralConnection(Peripheral)
        isConnected = false
    }
    
    func getManagerState() -> CBManagerState {
        return Manager.state
    }
    
    func writeByte(byte: UInt8) {
        var value = byte
        let dataValue = NSData(bytes: &value, length: MemoryLayout<UInt8>.size)
        Peripheral.writeValue(dataValue as Data, for: DEVICE_CHARACTERISTIC, type: .withoutResponse)
        print("Value sent: \(value)")
    }
    
    func flushTxBuffer() {
        if isConnected {
            txBufferDLE[0] = STX
            applyDLE()
            txBufferDLE[txLength] = ETX
            txLength += 1
            
            writeArray()
        }
    }
    
    func applyDLE() {
        var t = 1
        for i in 0...(txLength - 1) {
            if txBuffer[i] != STX && txBuffer[i] != ETX && txBuffer[i] != DLE {
                txBufferDLE[t] = txBuffer[i]
            }
            else if txBuffer[i] == STX {
                txBufferDLE[t] = DLE
                t += 1
                txBufferDLE[t] = A
            }
            else if txBuffer[i] == ETX {
                txBufferDLE[t] = DLE
                t += 1
                txBufferDLE[t] = B
            }
            else if txBuffer[i] == DLE {
                txBufferDLE[t] = DLE
                t += 1
                txBufferDLE[t] = C
            }
            t += 1
        }
        txLength = t
    }
    
    func writeArray() {
        var i = 0
        while txLength != 0 {
            let txByte = NSData(bytes: &txBufferDLE[i], length: MemoryLayout<UInt8>.size)
            Peripheral.writeValue(txByte as Data, for: DEVICE_CHARACTERISTIC, type: .withoutResponse)
            txLength -= 1
            i += 1
        }
    }
    
    func rxManager(_ inBytes: Data) {
        for inByte in inBytes {
            switch rxManagerState {
            case 0:
                if inByte == STX {
                    rxManagerState = 1
                    rxCounter = 0
                }
                break
            case 1:
                if inByte == ETX {
                    removeDLE()
                    analyzeRxBuffer()
                    rxManagerState = 0
                }
                else if inByte == STX {
                    rxCounter = 0
                }
                else {
                    rxBufferDLE[rxCounter] = inByte
                    rxCounter += 1
                }
                break
            default:
                break
            }
        }
    }
    
    func removeDLE() {
        var t = 0
        for i in 0...(rxCounter - 1) {
            if rxBufferDLE[t] != DLE {
                rxBuffer[i] = rxBufferDLE[t]
            }
            else {
                t += 1
                rxCounter -= 1
                if rxBufferDLE[t] == A {
                    rxBuffer[i] = STX;
                }
                else if rxBufferDLE[t] == B {
                    rxBuffer[i] = ETX;
                }
                else if rxBufferDLE[t] == C {
                    rxBuffer[i] = DLE;
                }
            }
            t += 1
        }
    }
    
    func analyzeRxBuffer() {
        switch rxBuffer[0] {
        case 0x10:
            if rxCounter == 5 {
                let args = rxBuffer[1...4]
                TransmissionsManager.RPMResponse(Array(args))
            }
            break
        case 0x11:
            if rxCounter == 2 {
                let args = rxBuffer[1]
                TransmissionsManager.batteryPercentageResponse(args)
            }
            break
        case 0x12:
            if rxCounter == 6 {
                let args = rxBuffer[1...5]
                TransmissionsManager.cellVoltagesResponse(Array(args))
            }
            break
        case 0x13:
            if rxCounter == 9 {
                let args = rxBuffer[1...8]
                TransmissionsManager.currentResponse(Array(args))
            }
            break
        case 0x14:
            let args = rxBuffer[1...rxCounter - 1]
            TransmissionsManager.boardNameResponse(Array(args))
        case 0x15:
            if rxCounter == 2 {
                let args = rxBuffer[1]
                TransmissionsManager.systemStatusResponse(args)
            }
        case 0x16:
            if rxCounter == 2 {
                let args = rxBuffer[1]
                TransmissionsManager.modeCodeResponse(args)
            }
        default:
            break
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == DEVICE_CHARACTERISTIC_UUID {
            rxManager(characteristic.value!)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == DEVICE_NAME {
            Peripheral = peripheral
            Peripheral.delegate = self
            Manager.stopScan()
            Manager.connect(Peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        isScanning = false
        isDiscovering = true
    }
    
    @objc func updateValues() {
        if isConnected {
            Peripheral.readRSSI()
        }
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
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == DEVICE_CHARACTERISTIC_UUID {
                    DEVICE_CHARACTERISTIC = characteristic
                    isDiscovering = false
                    isConnected = true
                    peripheral.setNotifyValue(true, for: DEVICE_CHARACTERISTIC)
                    delegate?.connectedToPeripheral()
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        SignalStrength = Int(truncating: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        delegate?.peripheralDisconnected()
    }
}
