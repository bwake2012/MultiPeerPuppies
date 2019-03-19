//
//  PeerSessionCoordinator.swift
//  MultiPeer
//
//  Created by Bob Wakefield on 4/12/17.
//  Copyright © 2017 Bob Wakefield. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

fileprivate let multiPeerServiceType = "cockleburr-peer"

fileprivate let kDataPeerID = "My Peer ID Data"

class PeerSessionCoordinator: NSObject {
    
    var peerID: MCPeerID
    var mcSession: MCSession
    var advertiserAssistant: MCAdvertiserAssistant!
    var serviceBrowser: MCNearbyServiceBrowser!
    var info: [String: String]
    
    weak var delegate: PeerSessionCoordinatorDelegate?
    
    // get the saved peer ID if one exists, otherwise create a new peer ID and save it
    init( name: String, info: [String: String], delegate: PeerSessionCoordinatorDelegate ) {
        
        self.delegate = delegate

        var tempPeerID: MCPeerID?

        let userDefaults = UserDefaults.standard
        if let dataPeerID = userDefaults.object(forKey: kDataPeerID) as? Data,
           let peerID = NSKeyedUnarchiver.unarchiveObject(with: dataPeerID ) as? MCPeerID {
            
            tempPeerID = peerID
        }

        if nil == tempPeerID {
        
            tempPeerID = MCPeerID( displayName: name )
            if let peerID = tempPeerID {

                let dataPeerID = NSKeyedArchiver.archivedData( withRootObject: peerID )
                userDefaults.set( dataPeerID, forKey: kDataPeerID )
                userDefaults.synchronize()
            }
        }
        
        guard let peerID = tempPeerID else {
            
            fatalError( "Unable to create a peer ID for an MCSession" )
        }
        
        mcSession = MCSession( peer: peerID, securityIdentity: nil, encryptionPreference: .required )
        self.peerID = peerID
        self.info = info
        
        super.init()

        mcSession.delegate = self
    }
    
    deinit {
        
        advertiserAssistant.stop()
        mcSession.disconnect()
    }
    
    var connectedPeerCount: Int { return mcSession.connectedPeers.count }
    
    fileprivate func updateConnectedPeerCount() -> Void {
        
        let peerCount = connectedPeerCount
        
        DispatchQueue.main.async {
            
            [weak self] in
            
            if let strongSelf = self, let delegate = strongSelf.delegate {
                
                delegate.peerCountChanged( count: peerCount )
            }
        }
    }

    func startHosting( action: UIAlertAction! ) {
        
        advertiserAssistant = MCAdvertiserAssistant( serviceType: multiPeerServiceType, discoveryInfo: self.info, session: mcSession )
        advertiserAssistant.start()
    }

    func startBrowsing() {
        
        serviceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: multiPeerServiceType )
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
    }

    func joinSession( action: UIAlertAction! ) {
        
        let mcBrowser = MCBrowserViewController( serviceType: multiPeerServiceType, session: mcSession )
        mcBrowser.delegate = self
        
        delegate?.presentBrowser( mcBrowser, animated: true )
    }
    
}

extension PeerSessionCoordinator: MCSessionDelegate {
    
    func sendImage( img: UIImage) {
        
        if mcSession.connectedPeers.count > 0 {
            
            if let imageData = UIImagePNGRepresentation(img) {
                
                do {
                    
                    try mcSession.send( imageData, toPeers: mcSession.connectedPeers, with: .reliable )
                    
                } catch let error as NSError {
                    
                    delegate?.displayError(operation: "Send Error", error: error )
                    
//                    DispatchQueue.main.async {
//                        let ac = UIAlertController( title: "Send error", message: error.localizedDescription, preferredStyle: .alert )
//                        ac.addAction( UIAlertAction( title: "OK", style: .default ) )
//                        vc.present( ac, animated: true )
//                    }
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        if let image = UIImage(data: data) {
            
            let displayName = peerID.displayName
            
            DispatchQueue.main.async {
                
                [weak self] in
                
                if let strongSelf = self {
                    
                    // do something with the image
                    strongSelf.delegate?.imageReceived( peerName: displayName, image: image )
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        switch state {
            
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            // serviceBrowser.stopBrowsingForPeers()
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
//            if 0 == mcSession.connectedPeers.count {
//                
//                startBrowsing()
//            }
        }
     
        updateConnectedPeerCount()
    }
}

extension PeerSessionCoordinator: MCBrowserViewControllerDelegate {

    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
        let peerCount = connectedPeerCount
        
        DispatchQueue.main.async {
            
            [weak self] in
            
            if let strongSelf = self, let delegate = strongSelf.delegate {
                
                strongSelf.delegate?.closeBrowser( true, animated: true )
                
                delegate.peerCountChanged( count: peerCount )
            }
        }
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        
        let peerCount = connectedPeerCount
        
        DispatchQueue.main.async {
            
            [weak self] in
            
            if let strongSelf = self, let delegate = strongSelf.delegate {
                
                delegate.closeBrowser( false, animated: true )
                
                delegate.peerCountChanged( count: peerCount )
            }
        }
    }
}

extension PeerSessionCoordinator: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) -> Void {
     
        print( "Did not start browsing for peers. Error: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Void {
        
        if let info = info, self.info == info {
            
            print( "Compatible peer: \(peerID) found.")
           
            let myHashedPeerID = self.peerID.hashValue
            let theirHashedPeerID = peerID.hashValue
            if myHashedPeerID < theirHashedPeerID {
                
                browser.invitePeer( peerID, to: mcSession, withContext: nil, timeout: 30.0 )
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) -> Void {
        
        print( "Lost peer: \(peerID)" )
    }
    
}

extension PeerSessionCoordinator {
    
    func connectedPeers( in session: Int ) -> Int {
        
        return connectedPeerCount
    }
    
    func numberOfSessions() -> Int {
        
        return 2
    }
    
    func peerAt( session: Int, connection: Int ) -> MCPeerID? {
        
        if 0 == session {
            return peerID
        } else if connection < connectedPeerCount {
            return mcSession.connectedPeers[connection]
        }
        
        return nil
    }
    
}

