//
//  MSIDisplaySwitchApp.swift
//  MSI Display Switch
//
//  Created by Валерий Агишев on 08.01.2025.
//

import SwiftUI
import IOKit.hid
import IOKit.usb
import os.log

let logger = Logger()


class DisplayController {
    static let singleton = DisplayController()
    
    let vendorId = 0x1462
    let productId = 0x3FA4
    let reportSize = 0x40
    
    private var device: IOHIDDevice? = nil
    
    var isConnected: Bool = false
    
    func input(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
        let message = Data(bytes: report, count: reportLength)
        logger.debug("get input: \([UInt8](message))")
    }
    
    func output(_ data: Data) {
        if (data.count > reportSize) {
            logger.error("output data too large for USB report")
            return
        }
        let reportId : CFIndex = CFIndex(data[0])
        if let dev = device {
            logger.debug("set output: \([UInt8](data))")
            IOHIDDeviceSetReport(dev, kIOHIDReportTypeOutput, reportId, [UInt8](data), data.count)
        }
    }
    
    func connected(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        logger.info("display connected: \(inIOHIDDeviceRef.debugDescription)")
        device = inIOHIDDeviceRef
        
        let report = UnsafeMutablePointer<UInt8>.allocate(capacity: reportSize)
        
        let inputCallback : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
            let this : DisplayController = Unmanaged<DisplayController>.fromOpaque(inContext!).takeUnretainedValue()
            this.input(inResult, inSender: inSender!, type: type, reportId: reportId, report: report, reportLength: reportLength)
        }
            
        let this = Unmanaged.passRetained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device!, report, reportSize, inputCallback, this)
        isConnected = true
    }
    
    func removed(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        logger.info("display disconnected")
        device = nil
        isConnected = false
    }
    
    @objc func connect() {
        logger.info("start display controller")
        let deviceMatch = [kIOHIDProductIDKey: self.productId, kIOHIDVendorIDKey: self.vendorId]
        let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
            
        IOHIDManagerSetDeviceMatching(managerRef, deviceMatch as CFDictionary?)
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(managerRef, 0)
            
        let matchingCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this: DisplayController = Unmanaged<DisplayController>.fromOpaque(inContext!).takeUnretainedValue()
            this.connected(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
            
        let removalCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : DisplayController = Unmanaged<DisplayController>.fromOpaque(inContext!).takeUnretainedValue()
            this.removed(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
            
        let this = Unmanaged.passRetained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, matchingCallback, this)
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, removalCallback, this)
        
        RunLoop.current.run()
    }
}

var daemon = Thread.init(target: DisplayController.singleton, selector:#selector(DisplayController.connect), object: nil)

@main
struct MSIDisplaySwitchApp: App {
    init() {
        daemon.start()
    }
    
    var body: some Scene {
        StatusBar(
            onHdmi1: {
                let bytes : [UInt8] = [
                    0x01, 0x35, 0x62, 0x30, 0x30, 0x35, 0x30, 0x30, 0x30, 0x30, 0x30, 0x0D, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00
                ]
                
                DisplayController.singleton.output(Data(bytes))
            },
            onHdmi2: {
                let bytes : [UInt8] = [
                    0x01, 0x35, 0x62, 0x30, 0x30, 0x35, 0x30, 0x30, 0x30, 0x30, 0x31, 0x0D, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00
                ]
                
                DisplayController.singleton.output(Data(bytes))
            },
            onDisplayPort: {
                let bytes : [UInt8] = [
                    0x01, 0x35, 0x62, 0x30, 0x30, 0x35, 0x30, 0x30, 0x30, 0x30, 0x32, 0x0D, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00
                ]
                
                DisplayController.singleton.output(Data(bytes))
            },
            onTypeC: {
                let bytes : [UInt8] = [
                    0x01, 0x35, 0x62, 0x30, 0x30, 0x35, 0x30, 0x30, 0x30, 0x30, 0x33, 0x0D, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00
                ]
                
                DisplayController.singleton.output(Data(bytes))
            }
        )
    }
}
