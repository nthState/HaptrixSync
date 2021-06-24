//
//  PeerConnection.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com.
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import Network
import os.log
import Combine

 class PeerConnection {
  
  var connection: NWConnection?
  let initiatedConnection: Bool
  
   enum ConnectionState {
    case ready
    case failed
  }
    
   var connectionStatePublisher = PassthroughSubject<ConnectionState, Never>()
  
   var receiveMessagePublisher = PassthroughSubject<(content: Data?, message: NWProtocolFramer.Message), Never>()
  
  deinit {
    os_log("deinit PeerConnection", log: .network, type: .debug)
  }
  
  /**
   Create an outbound connection when the user initiates a game.
   - Parameters:
   - endpoint: endpoint description
   - interface: interface description
   */
   init(endpoint: NWEndpoint, interface: NWInterface?) {
    self.initiatedConnection = true
    
    let connection = NWConnection(to: endpoint, using: NWParameters.haptrixParameters())
    self.connection = connection
    
    startConnection()
  }
  
  /**
   Handle an inbound connection when the user receives a game request.
   - Parameter connection: connection description
   */
  init(connection: NWConnection) {
    self.connection = connection
    self.initiatedConnection = false
    
    startConnection()
  }
  
  /**
   Handle the user exiting the game.
   */
   func cancel() {
    if let connection = self.connection {
      connection.cancel()
      self.connection = nil
    }
  }
  
  /**
   Handle starting the peer-to-peer connection for both inbound and outbound connections.
   */
  func startConnection() {
    guard let connection = connection else {
      return
    }
    
    connection.stateUpdateHandler = { [weak self] newState in
      
      switch newState {
      case .ready:
        os_log("Connection: established", log: .network, type: .debug)
        
        // When the connection is ready, start receiving messages.
        self?.receiveNextMessage()
        
        // Notify your delegate that the connection is ready.
        self?.connectionStatePublisher.send(.ready)
//        if let delegate = self.delegate {
//          delegate.connectionReady()
//        }
      case .failed(let error):
        os_log("Connection: failed", log: .network, type: .error, "\(error)")
        
        // Cancel the connection upon a failure.
        connection.cancel()
        
        // Notify your delegate that the connection failed.
//        if let delegate = self.delegate {
//          delegate.connectionFailed()
//        }
        self?.connectionStatePublisher.send(.failed)
      case .cancelled:
        os_log("Connection: Cancelled", log: .network, type: .debug)
      case .preparing:
        os_log("Connection: Preparing", log: .network, type: .debug)
      case .setup:
        os_log("Connection: Setup", log: .network, type: .debug)
      default:
        os_log("Connection: Unknown", log: .network, type: .debug)
      }
    }
    
    // Start the connection establishment.
    connection.start(queue: .main)
  }
      
  /**
   Send a ZIP file as data
   
   - Parameter data: ZIP file data
   */
   func send(zip data: Data) {

    let message = NWProtocolFramer.Message(messageType: .sendZIP)
    
    let context = NWConnection.ContentContext(identifier: "SNDZ",
                                              metadata: [message])
    
    // Send the application content along with the message.
    connection?.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
  }
  
  /**
   
   */
   func kill() {
    let message = NWProtocolFramer.Message(messageType: .kill)
    let context = NWConnection.ContentContext(identifier: "KILL",
                                                 metadata: [message])
    connection?.send(content: Data(), contentContext: context, isComplete: true, completion: .idempotent)
  }

 /**
   Receive a message, deliver it to your delegate, and continue receiving more messages.
   */
  func receiveNextMessage() {
    guard let connection = connection else {
      return
    }
    
    connection.receiveMessage { (content, context, isComplete, error) in
      // Extract your message type from the received context.
      if let message = context?.protocolMetadata(definition: MessageProtocol.definition) as? NWProtocolFramer.Message {
        self.receiveMessagePublisher.send((content: content, message: message))
      }
      if error == nil {
        // Continue to receive more messages until you receive and error.
        self.receiveNextMessage()
      }
    }
  }

}


