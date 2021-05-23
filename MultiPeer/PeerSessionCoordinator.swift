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

let keyPuppyPicture = "PuppyPicture"

fileprivate let multiPeerServiceType = "peer-puppies"

fileprivate let kDataPeerID = "My Peer ID Data"

class PeerSessionCoordinator: NSObject {
    
    var peerID: MCPeerID?
    var mcSession: MCSession?
    var advertiserAssistant: MCAdvertiserAssistant?
    var serviceBrowser: MCNearbyServiceBrowser?
    var info: [String: String] = [:]
    
    weak var delegate: PeerSessionCoordinatorDelegate?

    override init() {

        super.init()
    }
    
    // get the saved peer ID if one exists, otherwise create a new peer ID and save it
    init( name: String, info: [String: String], delegate: PeerSessionCoordinatorDelegate ) {
        
        self.delegate = delegate

        var tempPeerID: MCPeerID?

        let userDefaults = UserDefaults.standard
        if let dataPeerID = userDefaults.object(forKey: kDataPeerID) as? Data,
            let peerID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: dataPeerID ) {
            
            tempPeerID = peerID
        }

        if nil == tempPeerID {
        
            tempPeerID = MCPeerID( displayName: name )
            if let peerID = tempPeerID {

                if let dataPeerID = try? NSKeyedArchiver.archivedData(withRootObject: peerID, requiringSecureCoding: true) {

                    userDefaults.set( dataPeerID, forKey: kDataPeerID )
                    userDefaults.synchronize()
                }
            }
        }
        
        guard let peerID = tempPeerID else {
            
            fatalError( "Unable to create a peer ID for an MCSession" )
        }
        
        mcSession = MCSession( peer: peerID, securityIdentity: nil, encryptionPreference: .required )
        self.peerID = peerID
        self.info = info
        
        super.init()

        mcSession?.delegate = self
    }
    
    deinit {
        
        advertiserAssistant?.stop()
        mcSession?.disconnect()
    }
    
    var connectedPeerCount: Int { return mcSession?.connectedPeers.count ?? 0 }
    
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

        guard let mcSession = self.mcSession else {

            return
        }
        
        advertiserAssistant = MCAdvertiserAssistant( serviceType: multiPeerServiceType, discoveryInfo: self.info, session: mcSession )
        advertiserAssistant?.start()
    }

    func startBrowsing() {

        guard let peerID = self.peerID else {

            return
        }

        let serviceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: multiPeerServiceType )
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
        self.serviceBrowser = serviceBrowser
    }

    func joinSession( action: UIAlertAction! ) {

        guard let mcSession = self.mcSession else {

            return
        }
        
        let mcBrowser = MCBrowserViewController( serviceType: multiPeerServiceType, session: mcSession )
        mcBrowser.delegate = self
        
        delegate?.presentBrowser( mcBrowser, animated: true )
    }
    
}

extension PeerSessionCoordinator: MCSessionDelegate {
    
    func sendImage( img: UIImage) {

        guard let mcSession = self.mcSession else { return }
        
        if mcSession.connectedPeers.count > 0 {

            guard let imageData = archiveImage(image: img) else {

                delegate?.displayError(operation: "Archive image to send", error: nil)
                return
            }

            do {

                try mcSession.send( imageData, toPeers: mcSession.connectedPeers, with: .reliable )

            } catch let error as NSError {

                delegate?.displayError(operation: "Send Error", error: error )
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {

        guard let image = unarchiveImage(data: data) else {

            delegate?.displayError(operation: "Unarchive received image data", error: nil)
            return
        }

        let displayName = peerID.displayName

        DispatchQueue.main.async {

            [weak self] in

            if let strongSelf = self {

                // do something with the image
                strongSelf.delegate?.imageReceived( peerName: displayName, image: image )
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
            
        @unknown default:
            break
        }
     
        updateConnectedPeerCount()
    }
}

// Add this optional function in MCSessionDelegate to make the session connection much more reliable
// If you validate connections with certificates, here is where you do that.
extension PeerSessionCoordinator {

    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        
        guard nil == certificate || certificate?.isEmpty ?? true else {
            
            fatalError("Session certificates received without validation implemented.")
        }
        
        certificateHandler(true)
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

        guard let mcSession = self.mcSession else { return }
        
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

        guard let mcSession = self.mcSession else { return nil }

        if 0 == session {
            return peerID
        } else if connection < connectedPeerCount {

            return mcSession.connectedPeers[connection]
        }
        
        return nil
    }
    
}

extension PeerSessionCoordinator {

    func archiveImage(image: UIImage) -> Data? {

        let archiver = NSKeyedArchiver(requiringSecureCoding: true)

        guard let imageData: Data = image.pngData() else { return nil }

        let imageDataString: String = imageData.base64EncodedString()

        archiver.encode(imageDataString, forKey: keyPuppyPicture)

        archiver.finishEncoding()

        return archiver.encodedData
    }

    func unarchiveImage(data: Data) -> UIImage? {

        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
        unarchiver.requiresSecureCoding = true

        guard let imageDataString: String = unarchiver.decodeDecodable(String.self, forKey: keyPuppyPicture) else { return nil }
        unarchiver.finishDecoding()

        guard let imageData = Data(base64Encoded: imageDataString) else { return nil }

        let image = UIImage(data: imageData)

        return image
    }
}
