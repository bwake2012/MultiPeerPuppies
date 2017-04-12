//
//  ViewController.swift
//  MultiPeer
//
//  Created by Bob Wakefield on 4/11/17.
//  Copyright © 2017 Bob Wakefield. All rights reserved.
//

import UIKit
import MultipeerConnectivity

fileprivate let info = ["subject": "puppydemo"]

class ViewController: UIViewController {
    
    fileprivate var peerSessionCoordinator: PeerSessionCoordinator?
    
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var receivedImage: UIImageView!
    @IBOutlet weak var senderPeerName: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    
    @IBAction func avatarButton(_ sender: UIButton) {
        
        if let image = sender.imageView?.image {

            peerSessionCoordinator?.sendImage( img: image )
        }
    }
    
    @IBAction func connectTapped(_ sender: UIButton) {

        let actionHandler = { ( action: UIAlertAction ) -> Void in }
        
        let alertAction = UIAlertAction( title: "Hurray!", style: .default, handler: actionHandler )
        
        peerSessionCoordinator?.joinSession( action: alertAction )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        peerSessionCoordinator = PeerSessionCoordinator( name: UIDevice.current.name, delegate: self )
    }

    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear( animated )
        
        let actionHandler = { ( action: UIAlertAction ) -> Void in }
        let alertAction = UIAlertAction( title: "Huzza!", style: .default, handler: actionHandler )
        peerSessionCoordinator?.startHosting( info: info, action: alertAction )

    }
}

extension ViewController: PeerSessionCoordinatorDelegate {
    
    func imageReceived( peerName: String, image: UIImage ) -> Void {
        
        DispatchQueue.main.async {
            
            [weak self] in
            
            if let strongSelf = self {
                
                strongSelf.receivedImage.image = image
                
                strongSelf.senderPeerName.text = "Sent from: " + peerName
            }
        }
    }
    
    func displayError( operation: String, error: NSError ) -> Void {
        
        DispatchQueue.main.async {
            
            [weak self] in
            
            if let strongSelf = self {
                
                let ac = UIAlertController( title: operation, message: error.localizedDescription, preferredStyle: .alert )
                ac.addAction( UIAlertAction( title: "OK", style: .default ) )
                strongSelf.present( ac, animated: true )
            }
        }
    }
    
    func peerCountChanged( count: Int ) -> Void {
        
        DispatchQueue.main.async {
            
            [weak self] in
            
            if let strongSelf = self {
                
                strongSelf.stateLabel.text = "Connections: \(count)"
            }
        }
    }
    
    func presentBrowser( _ vc: UIViewController, animated: Bool ) -> Void {
        
        DispatchQueue.main.async {
            
            [weak self] in
            
            if let strongSelf = self {
                
                strongSelf.present( vc, animated: animated )
            }
        }
    }
    
    func closeBrowser( _ success: Bool, animated: Bool ) -> Void {
        
        DispatchQueue.main.async {
            
            [weak self] in
            
            if let strongSelf = self {
                
                strongSelf.dismiss( animated: animated )
            }
        }
    }
}

