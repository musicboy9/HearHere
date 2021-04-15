//
//  bluetoothPeripheralSearcher1.swift
//  HearHereVer2
//
//  Created by 고영민 on 2016. 8. 2..
//  Copyright © 2016년 고영민. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothPeripheralSearcher: NSObject, DZBluetoothSerialDelegate {
    
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = [] {
        didSet {
            if self.peripherals.count > 0 {
                self.temp.append(contentsOf: self.peripherals)
            }
        }
    }// 검색된 peripheral들의 list.
    
    var temp: [(peripheral: CBPeripheral, RSSI: Float)] = []

    var scanDone = false
    
    var deviceConnected = false

    var devicePeripheralIndex = 0
    
    var deviceExistence = false {
        didSet {
            if deviceExistence {
                let devicePeripheral = self.peripherals[devicePeripheralIndex].peripheral
                serial.connectToPeripheral(peripheral: devicePeripheral)
            }
        }
    }
    
    override init() {
        super.init()
        serial = DZBluetoothSerialHandler(delegate: self)
        serial.writeWithResponse = UserDefaults.standard.bool(forKey: "WriteWithResponse")
        //serial initiallizing
        
        scanForPeripherials()
    }
    
//MARK: functions
    
    func scanForPeripherials(){
        serial.scanForPeripherals()
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.scanTimeOut) , userInfo: nil, repeats: false)
    }
    
//MARK: selector
    
    func scanTimeOut() {
        serial.stopScanning()
        print("scanDone")
        print(self.peripherals)
        print(self.temp)
        self.scanDone = true
        for existingPeripheralIndex in 0..<self.peripherals.count {
            print(self.peripherals[existingPeripheralIndex].peripheral.name!)
            if self.peripherals[existingPeripheralIndex].peripheral.name! == Optional("HMSoft") {
                print(1)
                self.deviceExistence = true
                self.devicePeripheralIndex = existingPeripheralIndex
                break
            }
        }
        
        if self.deviceExistence {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "deviceScanned"), object: nil)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "noDevice"), object: nil)
        }
    }
    
//MARK: DZBluetoothSerialDelegate
    
    func serialHandlerDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber) {
        
        print("Discovered")
        print(peripheral.name)
        print(self.peripherals)
        
        for existingPeripheral in self.peripherals {
            if existingPeripheral.peripheral.identifier == peripheral.identifier { return }
        }
        
        self.peripherals.append((peripheral: peripheral, RSSI: RSSI.floatValue))
        self.peripherals.sort { $0.RSSI < $1.RSSI }
        
        print(self.peripherals)
        print(2222)
    }
    
    func serialHandlerDidDisconnect(peripheral: CBPeripheral, error: NSError?) {
        self.deviceConnected = false
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "deviceConnectionFailure"), object: nil)
    }
    
    func serialHandlerDidFailToConnect(peripheral: CBPeripheral, error: NSError?) {
        self.deviceConnected = false
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "deviceConnectionFailure"), object: nil)
    }
    
    func serialHandlerDidConnect(peripheral: CBPeripheral) {
        self.deviceConnected = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "deviceConnected"), object: nil)
    }
    
}
