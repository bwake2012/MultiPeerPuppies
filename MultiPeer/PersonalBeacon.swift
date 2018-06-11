//
//  PersonalBeacon.swift
//  MultiPeerPuppies
//
//  Created by Bob Wakefield on 4/23/17.
//  Copyright © 2017 Bob Wakefield. All rights reserved.
//

import Foundation

import CoreBluetooth
import CoreLocation

let beaconIdentifier = "net.cockleburr.MultiPeerPuppies"

class PersonalBeacon : NSObject {
    
    var peripheralData: [String: Any]?
    
    lazy var peripheralManager: CBPeripheralManager = {
        
        let queue = DispatchQueue( label: "net.cockleburr.MultiPeerPuppies.CBPeripheralManager" )
        
        let manager = CBPeripheralManager( delegate: self, queue: queue )
        manager.delegate = self
        return manager
    }()
    
    var bluetoothEnabled: Bool {
        
        let state = self.peripheralManager.state
        
        return state == .poweredOn
    }

    init?( uuid: UUID, major: Int, minor: Int, power: NSNumber? ) {
        
        super.init()

        guard bluetoothEnabled else {

           print( "bluetooth not enabled" )

//            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Bluetooth must be enabled" message:@"To configure your device as a beacon" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//            [errorAlert show];
            
            return nil
        }

        // We must construct a CLBeaconRegion that represents the payload we want the device to beacon.
        var region: CLBeaconRegion?
        
        if major > 0 && minor > 0 {
            
            region = CLBeaconRegion(proximityUUID: uuid, major: CLBeaconMajorValue(major), minor: CLBeaconMinorValue(minor), identifier: beaconIdentifier )
            
        }
        else if major > 0 {
            
            region = CLBeaconRegion(proximityUUID: uuid, major: CLBeaconMajorValue(major), identifier: beaconIdentifier )

        } else {
            
            region = CLBeaconRegion(proximityUUID: uuid, identifier: beaconIdentifier )
        }
        
        // The region's peripheral data contains the CoreBluetooth-specific data we need to advertise.
        if let region = region {
            
            peripheralData = region.peripheralData( withMeasuredPower: power ) as? [String : Any]

        }
        
        peripheralManager.startAdvertising(peripheralData)
        
        let isAdvertising = self.peripheralManager.isAdvertising
        
        if !isAdvertising {
            
            return nil
        }
    }

    deinit {
        
        self.peripheralManager.stopAdvertising()
    }
}

extension PersonalBeacon: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        switch peripheral.state {
        case .poweredOff:
            break
        case .poweredOn:
            guard let peripheralData = self.peripheralData else {
                return
            }
            peripheralManager.startAdvertising( peripheralData )
        case .resetting:
            break
        case .unauthorized:
            break
        case .unknown:
            break
        case .unsupported:
            break
        }
    }
}
