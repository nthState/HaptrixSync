//
//  HaptrixNetworkBrowser.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import Network
import Combine
import os.log

class PeerBrowser {
  
  private var browser: NWBrowser?
  
  deinit {
    os_log("deinit PeerBrowser", log: .network, type: .debug)
  }
  
  var resultsPublisher = PassthroughSubject<Set<NWBrowser.Result>, Never>()
  
  /**
   Start browsing for services.
   */
  func startBrowsing() {
    // Create parameters, and allow browsing over peer-to-peer link.
    let parameters = NWParameters()
    parameters.includePeerToPeer = true
    
    // Browse for a custom "_haptrix._tcp" service type.
    let browser = NWBrowser(for: .bonjour(type: bonjourType, domain: nil), using: parameters)
    self.browser = browser
    browser.stateUpdateHandler = { [weak self] newState in
      switch newState {
      case .failed(let error):
        // Restart the browser if it fails.
        os_log("Network error: %@", log: .network, type: .error, "Browser failed with \(error), restarting")
        self?.browser?.cancel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
          self?.startBrowsing()
        }
      case .setup:
        os_log("Browser setup", log: .network, type: .debug)
      case .ready:
        os_log("Browser ready", log: .network, type: .debug)
      case .cancelled:
        os_log("Browser cancelled", log: .network, type: .debug)
      default:
        os_log("Browser unknown", log: .network, type: .debug)
      }
    }
    
    // When the list of discovered endpoints changes, refresh the delegate.
    browser.browseResultsChangedHandler = { [weak self] results, changes in
      self?.resultsPublisher.send(results)
    }
    
    // Start browsing and ask for updates on the main queue.
    browser.start(queue: .main)
  }
  
  /**
   Cancel browsing
   */
  func cancelBrowsing() {
    browser?.cancel()
  }
}

