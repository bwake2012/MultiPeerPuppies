//
//  PeerSessionCoordinator.swift
//  MultiPeer
//
//  Created by Bob Wakefield on 4/12/17.
//  Copyright © 2017 Bob Wakefield. All rights reserved.
//

import UIKit
import MultipeerConnectivity

fileprivate let multiPeerServiceType = "cockleburr-peer"

protocol PeerSessionCoordinatorDelegate: class {
    
    func imageReceived( peerName: String, image: UIImage ) -> Void
    
    func displayError( operation: String, error: NSError ) -> Void
    
    func peerCountChanged( count: Int ) -> Void
    
    func presentBrowser( _ vc: UIViewController, animated: Bool ) -> Void
    
    func closeBrowser( _ success: Bool, animated: Bool ) -> Void
}

class PeerSessionCoordinator: NSObject {
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    weak var delegate: PeerSessionCoordinatorDelegate?
    
    init( name: String, delegate: PeerSessionCoordinatorDelegate ) {
        
        self.delegate = delegate

        peerID = MCPeerID( displayName: name )
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()

        mcSession.delegate = self
    }
    
    deinit {
        
        mcAdvertiserAssistant.stop()
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

    func startHosting( info: [String: String], action: UIAlertAction! ) {
        
        mcAdvertiserAssistant = MCAdvertiserAssistant( serviceType: multiPeerServiceType, discoveryInfo: info, session: mcSession )
        mcAdvertiserAssistant.start()
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
                    
//                    let ac = UIAlertController( title: "Send error", message: error.localizedDescription, preferredStyle: .alert )
//                    ac.addAction( UIAlertAction( title: "OK", style: .default ) )
//                    vc.present( ac, animated: true )
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
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        switch state {
            
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
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
