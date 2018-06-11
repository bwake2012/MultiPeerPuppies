//
//  ConnectionViewController.swift
//  MultiPeerPuppies
//
//  Created by Bob Wakefield on 5/19/17.
//  Copyright © 2017 Bob Wakefield. All rights reserved.
//

import UIKit

class ConnectionViewController: UIViewController {

    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var peerSessionCoordinator: PeerSessionCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear( animated )
        
        tableView.reloadData ()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ConnectionViewController: UITableViewDelegate {
    
}

extension ConnectionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let connectionCount = peerSessionCoordinator.connectedPeers( in: section )
        DispatchQueue.main.async {
            
            [weak self] in
            
            if let strongSelf = self {
                
                strongSelf.stateLabel.text = "Connections: \(connectionCount)"
            }
        }
        
        return connectionCount
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {

        return peerSessionCoordinator.numberOfSessions()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let peer = peerSessionCoordinator.peerAt( session: indexPath.section, connection: indexPath.row )
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "connectedPeer", for: indexPath )
        
        cell.textLabel?.text = peer?.displayName ?? "* Unknown Peer *"
        
        return cell
    }
}
