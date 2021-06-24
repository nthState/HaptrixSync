//
//  Networking.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import Network
import os.log
import Combine

/// Name of Haptrix Bonjour service
let bonjourType = "_haptrix._tcp"

private var sharedBrowser: PeerBrowser?
private var sharedConnection: PeerConnection?

class Networking {
  
  static let shared = Networking()
  
  private var connections: Set<NWBrowser.Result> = []
  private var resultsCancellable: AnyCancellable?
  private var connectionStateCancellable: AnyCancellable?
  private var receiveMessageCancellable: AnyCancellable?
  private var sync: NetworkDataDelegate
  
  deinit {
    os_log("deinit Networking", log: .network, type: .debug)
  }
  
  /**
   
   */
  init() {
    
    sync = NetworkDataDelegate()
    
    sharedBrowser = PeerBrowser()
    sharedBrowser?.startBrowsing()
    
    resultsCancellable = sharedBrowser?
      .resultsPublisher
      .sink(receiveCompletion: { (result) in
        switch result {
        case .failure(let error):
          os_log("Sync error: %@", log: .network, type: .error, "\(error)")
        case .finished:
          os_log("finished", log: .network, type: .debug)
        }
      }, receiveValue: { results in
        os_log("%@", log: .network, type: .debug, "Peer results: \(results)")
        
        // Let's connect to the first item in the list
        // NOTE: In the future, we may want to be smarter here about
        // Which device we connect to.
        guard let firstResult = results.first else {
          return
        }
        
        self.connect(to: firstResult)
        
      })
    
  }
  
  /**
   Connect to a specific result
   
   - Parameter result: Device to connect to
   */
  func connect(to result: NWBrowser.Result) {
    sharedConnection = PeerConnection(endpoint: result.endpoint,
                                      interface: result.interfaces.first)
    
    connectionStateCancellable = sharedConnection?
      .connectionStatePublisher
      .sink(receiveValue: { (state) in
        
        switch state {
        case .failed:
          os_log("Failed connection", log: .network, type: .debug)
        case .ready:
          os_log("Connection ready", log: .network, type: .debug)
        }
        
      })
    
    receiveMessageCancellable = sharedConnection?
      .receiveMessagePublisher
      .sink(receiveValue: { [weak self] (result) in
        
        switch result.message.messageType {
        case .invalid:
          os_log("Invalid message", log: .network, type: .debug)
        case .kill:
          sharedConnection?.cancel()
          sharedConnection = nil
          os_log("Connection killed", log: .network, type: .debug)
        case .sendZIP:
          os_log("receive zip", log: .network, type: .debug)
          guard let data = result.content else {
            return
          }
          self?.sync.receive(data: data)
        default:
          os_log("Unknown event %@", log: .network, type: .error, "\(result.message.messageType)")
        }
        
      })
  }
  
}


