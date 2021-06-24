//
//  NWParameters+Extensions.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import Network

extension NWParameters {

  /**
   Create parameters for use in PeerConnection.
   - Returns: NWParameters
   */
  static func haptrixParameters() -> NWParameters {
    
    let tcpOptions = NWProtocolTCP.Options()
    tcpOptions.enableKeepalive = true
    tcpOptions.keepaliveIdle = 2

    // Create parameters with custom TLS and TCP options.
    let parameters = NWParameters(tls: nil, tcp: tcpOptions)

    // Enable using a peer-to-peer link.
    parameters.includePeerToPeer = true

    // Add your custom message protocol to support our messages.
    let messageOptions = NWProtocolFramer.Options(definition: MessageProtocol.definition)
    parameters.defaultProtocolStack.applicationProtocols.insert(messageOptions, at: 0)
    
    return parameters
  }
  
}
