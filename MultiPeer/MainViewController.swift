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

fileprivate let beaconLabels = ["OFF", "ON"]

fileprivate let guid: UUID! = UUID( uuidString: "9CAB870B-8319-46F4-BBA6-F21F424A13E6" )

class MainViewController: UIViewController {
    
    fileprivate lazy var peerSessionCoordinator: PeerSessionCoordinator = PeerSessionCoordinator( name: UIDevice.current.name, info: info, delegate: self )
    
    fileprivate var personalBeacon: PersonalBeacon?

    @IBOutlet weak var embeddedTableViewController: ConnectionViewController?
    
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var receivedImage: UIImageView!
    @IBOutlet weak var senderPeerName: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var beaconOnOff: UIButton!
    @IBOutlet weak var beaconGUID: UILabel!
    
    @IBAction func avatarButton(_ sender: UIButton) {
        
        if let image = sender.imageView?.image {

            peerSessionCoordinator.sendImage( img: image )
        }
    }
    
    @IBAction func connectTapped(_ sender: UIButton) {

        let actionHandler = { ( action: UIAlertAction ) -> Void in }
        
        let alertAction = UIAlertAction( title: "Hurray!", style: .default, handler: actionHandler )
        
        peerSessionCoordinator.joinSession( action: alertAction )
    }

    @IBAction func beaconOnOffTapped( _ sender: UIButton ) {
        
        if nil == self.personalBeacon {
            
            self.personalBeacon = PersonalBeacon( uuid: guid, major: 100, minor: 1, power: nil );
        
        } else {
            
            self.personalBeacon = nil
        }
        
        sender.setTitle( "iBeacon is " + ( nil == self.personalBeacon ? "OFF" : "ON" ), for: .normal )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        let actionHandler = { ( action: UIAlertAction ) -> Void in }
        let alertAction = UIAlertAction( title: "Huzza!", style: .default, handler: actionHandler )
        peerSessionCoordinator.startHosting( action: alertAction )
        peerSessionCoordinator.startBrowsing();
        
        beaconGUID.text = guid?.uuidString
    }

    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear( animated )
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if "showConnectionTableView" == segue.identifier {
            
            if let targetVC = segue.destination as? ConnectionViewController {
                
                targetVC.peerSessionCoordinator = peerSessionCoordinator
                embeddedTableViewController = targetVC
            }
        }
    }
}

extension MainViewController: PeerSessionCoordinatorDelegate {
    
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
                strongSelf.embeddedTableViewController?.tableView.reloadData()
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

