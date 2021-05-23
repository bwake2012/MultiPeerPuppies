//
//  PeerSessionCoordinatorDelegate.swift
//  MultiPeerPuppies
//
//  Created by Bob Wakefield on 5/29/17.
//  Copyright © 2017 Bob Wakefield. All rights reserved.
//

import UIKit

protocol PeerSessionCoordinatorDelegate: AnyObject {
    
    func imageReceived( peerName: String, image: UIImage ) -> Void
    
    func displayError( operation: String, error: NSError? ) -> Void
    
    func peerCountChanged( count: Int ) -> Void
    
    func presentBrowser( _ vc: UIViewController, animated: Bool ) -> Void
    
    func closeBrowser( _ success: Bool, animated: Bool ) -> Void
}

