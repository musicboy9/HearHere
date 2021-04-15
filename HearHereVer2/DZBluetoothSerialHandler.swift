//
//  DZBluetoothSerialHandler.swift
//  HM10 Serial
//
//  Created by Alex on 09-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//
//  IMPORTANT: Don't forget to set the variable 'writeWithResponse' or else DZBluetoothSerialHandler might not work.
//

import UIKit
import CoreBluetooth

/// Global serial handler, don't forget to initialize it with init(delgate:)
var serial: DZBluetoothSerialHandler!

@objc protocol DZBluetoothSerialDelegate: NSObjectProtocol {
    
    /// Called when a message is received
    @objc optional func serialHandlerDidReceiveMessage(message: String)
    
    /// Called when de state of the CBCentralManager changes (e.g. when bluetooth is turned on/off)
    @objc optional func serialHandlerDidChangeState(newState: CBManagerState)
    
    /// Called when a new peripheral is discovered while scanning. Also gives the RSSI (signal strength)
    @objc optional func serialHandlerDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber)
    
    /// Called when a peripheral is connected (but not yet ready for cummunication)
    @objc optional func serialHandlerDidConnect(peripheral: CBPeripheral)
    
    /// Called when a peripheral disconnected
    @objc optional func serialHandlerDidDisconnect(peripheral: CBPeripheral, error: NSError?)
    
    /// Called when a pending connection failed
    @objc optional func serialHandlerDidFailToConnect(peripheral: CBPeripheral, error: NSError?)
    
    /// Called when a peripheral is ready for communication
    @objc optional func serialHandlerIsReady(peripheral: CBPeripheral)
}


final class DZBluetoothSerialHandler: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
//MARK: Variables
    
    /// The delegate object the DZBluetoothDelegate methods will be called upon
    var delegate: DZBluetoothSerialDelegate!
    
    /// The CBCentralManager this bluetooth serial handler uses for communication
    var centralManager: CBCentralManager!
    
    /// The connected peripheral (nil if none is connected)
    var connectedPeripheral: CBPeripheral?
    
    /// The string buffer received messages will be stored in
    var buffer = ""
    
    /// The state of the bluetooth manager (use this to determine whether it is on or off or disabled etc)
    var state: CBManagerState { get { return centralManager.state } }
    
    /// Whether to write to the HM10 with or without response.
    /// Legit HM10 modules (from JNHuaMao) require 'Write without Response',
    /// while fake modules (e.g. from Bolutek) require 'Write with Response'.
    var writeWithResponse = false
    
    
//MARK: functions
    
    /// Always use this to initialize an instance
    init(delegate: DZBluetoothSerialDelegate) {
        super.init()
        self.delegate = delegate
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Start scanning for peripherals
    func scanForPeripherals() {
        if centralManager.state != .poweredOn { return }
        centralManager.scanForPeripherals(withServices: nil, options: nil) //TODO: Try with service not nil (FFE0 or something)
    }
    
    /// Stop scanning for peripherals
    func stopScanning() {
        centralManager.stopScan()
    }
    
    /// Try to connect to the given peripheral
    func connectToPeripheral(peripheral: CBPeripheral) {
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    
    /// Disconnect from the connected peripheral (to be used while already connected to it)
    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
    }
    
    /// Disconnect from the given peripheral (to be used while trying to connect to it)
    func cancelPeripheralConnection(peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    
    /// Send a string to the device
    func sendMessageToDevice(message: String) {
        
        if centralManager.state != .poweredOn || connectedPeripheral == nil { return }
        
        let writeType: CBCharacteristicWriteType = writeWithResponse ? .withResponse : .withoutResponse
        
        // write the value to all characteristics of all services
        for service in connectedPeripheral!.services! {
            for characteristic in service.characteristics! {
                connectedPeripheral!.writeValue(message.data(using: String.Encoding.utf8)!, for: characteristic, type: writeType)
            }
        }
        
    }
    
    //TODO: Function to send 'raw' bytes (array of UInt8's) to the peripheral
    
    /// Gives the content of the buffer and empties the buffer
    func read() -> String {
        let str = "\(buffer)" // <- is dit wel nodig??
        buffer = ""
        return str
    }
    
    /// Gives the content of the buffer without emptying it
    func peek() -> String {
        return buffer
    }
    
    
//MARK: CBCentralManagerDelegate functions

    @objc(centralManager:didDiscoverPeripheral:advertisementData:RSSI:) func centralManager(_ didDiscovercentral: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : AnyObject], rssi RSSI: NSNumber) {
        if delegate.responds(to: #selector(DZBluetoothSerialDelegate.serialHandlerDidDiscoverPeripheral)) {
            // just send it to the delegate
            delegate.serialHandlerDidDiscoverPeripheral!(peripheral: peripheral, RSSI: RSSI)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if delegate.responds(to: #selector(DZBluetoothSerialDelegate.serialHandlerDidConnect)) {
            // send it to the delegate
            delegate.serialHandlerDidConnect!(peripheral: peripheral)
        }
        
        peripheral.delegate = self
        
        // Okay, the peripheral is connected but we're not ready yet! 
        // First get all services
        // Then get all characteristics of all services
        // Once that has been done check whether our characteristic (0xFFE1) is available
        // If it is, subscribe to it, and then we're ready for communication
        // If it is not, we've failed and have to find another device..

        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        connectedPeripheral = nil
        if delegate.responds(to: #selector(DZBluetoothSerialDelegate.serialHandlerDidDisconnect)) {
            // send it to the delegate
            delegate.serialHandlerDidDisconnect!(peripheral: peripheral, error: error)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: NSError?) {
        if delegate.responds(to: #selector(DZBluetoothSerialDelegate.serialHandlerDidFailToConnect)) {
            // just send it to the delegate
            delegate.serialHandlerDidFailToConnect!(peripheral: peripheral, error: error)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if delegate.responds(to: #selector(DZBluetoothSerialDelegate.serialHandlerDidChangeState)) {
            // just send it to the delegate
            delegate.serialHandlerDidChangeState!(newState: central.state)
        }
    }
    
    
//MARK: CBPeripheralDelegate functions
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        // discover all characteristics for all services
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: NSError?) {
        // check whether the characteristic we're looking for (0xFFE1) is present
        for characteristic in service.characteristics! {
            if characteristic.uuid == CBUUID(string: "FFE1") {
                connectedPeripheral = peripheral
                // subscribe to this value (so we'll get notified when there is serial data for us..)
                peripheral.setNotifyValue(true, for: characteristic)
                if delegate.responds(to: #selector(DZBluetoothSerialDelegate.serialHandlerIsReady)) {
                    // notify the delegate we're ready for communication
                    delegate.serialHandlerIsReady!(peripheral: peripheral)
                }
            }
        }
        
        //TODO: A way to notify the delegate if there is no FFE1 characteristic!
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: NSError?) {
        
        // there is new data for us! Update the buffer!
        if let newStr = String(data: characteristic.value!, encoding: String.Encoding.utf8) {
            buffer += newStr
            
            // notify the delegate of the new string
            if delegate.responds(to: #selector(DZBluetoothSerialDelegate.serialHandlerDidReceiveMessage)) {
                delegate!.serialHandlerDidReceiveMessage!(message: newStr)
            }
 
        } else {
            print("** Received an invalid string! **")
        }
    }

}
