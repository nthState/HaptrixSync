//
//  MessageProtocol.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import Foundation
import Network
import os.log

// Define the types of commands your game will use.
enum MessageType: UInt32 {
  case invalid = 0
  @available(*, deprecated, message: "Send data via sendZIP instead")
  case sendAHAP = 1
  case kill = 2
  case sendZIP = 3
}

class MessageProtocol : NWProtocolFramerImplementation {
  
  static let definition = NWProtocolFramer.Definition(implementation: MessageProtocol.self)
  
  static var label: String { return "AHAP" }
  
  // Set the default behavior for most framing protocol functions.
  required init(framer: NWProtocolFramer.Instance) { }
  func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { return .ready }
  func wakeup(framer: NWProtocolFramer.Instance) { }
  func stop(framer: NWProtocolFramer.Instance) -> Bool { return true }
  func cleanup(framer: NWProtocolFramer.Instance) { }
  
  /**
   Whenever the application sends a message, add your protocol header and forward the bytes.
   - Parameters:
   - framer: framer description
   - message: message description
   - messageLength: messageLength description
   - isComplete: isComplete description
   */
  func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
    // Extract the type of message.
    let type = message.messageType
    
    // Create a header using the type and length.
    let header = MessageProtocolHeader(type: type.rawValue, length: UInt32(messageLength))
    
    // Write the header.
    framer.writeOutput(data: header.encodedData)
    
    // Ask the connection to insert the content of the application message after your header.
    do {
      try framer.writeOutputNoCopy(length: messageLength)
    } catch let error {
      os_log("error: %@", log: .network, type: .error, "\(error)")
    }
  }
  
  /**
   Whenever new bytes are available to read, try to parse out your message format.
   - Parameter framer: framer description
   - Returns: description
   */
  func handleInput(framer: NWProtocolFramer.Instance) -> Int {
    while true {
      // Try to read out a single header.
      var tempHeader: MessageProtocolHeader? = nil
      let headerSize = MessageProtocolHeader.encodedSize
      let parsed = framer.parseInput(minimumIncompleteLength: headerSize,
                                     maximumLength: headerSize) { (buffer, isComplete) -> Int in
        guard let buffer = buffer else {
          return 0
        }
        if buffer.count < headerSize {
          return 0
        }
        tempHeader = MessageProtocolHeader(buffer)
        return headerSize
      }
      
      // If you can't parse out a complete header, stop parsing and ask for headerSize more bytes.
      guard parsed, let header = tempHeader else {
        return headerSize
      }
      
      // Create an object to deliver the message.
      var messageType = MessageType.invalid
      if let parsedMessageType = MessageType(rawValue: header.type) {
        messageType = parsedMessageType
      }
      let message = NWProtocolFramer.Message(messageType: messageType)
      
      // Deliver the body of the message, along with the message object.
      if !framer.deliverInputNoCopy(length: Int(header.length), message: message, isComplete: true) {
        return 0
      }
    }
  }
  
}

// Extend framer messages to handle storing your command types in the message metadata.
extension NWProtocolFramer.Message {
  
  /**
   
   - Parameter messageType: messageType description
   */
  convenience init(messageType: MessageType) {
    self.init(definition: MessageProtocol.definition)
    
    self.messageType = messageType
  }
  
  var messageType: MessageType {
    get {
      if let type = self["AHAPMessageType"] as? MessageType {
        return type
      } else {
        return .invalid
      }
    }
    set {
      self["AHAPMessageType"] = newValue
    }
  }
  
}

// Define a protocol header struct to help encode and decode bytes.
struct MessageProtocolHeader: Codable {
  
  let type: UInt32
  let length: UInt32
  
  /**
   
   - Parameters:
   - type: type description
   - length: length description
   */
  init(type: UInt32, length: UInt32) {
    self.type = type
    self.length = length
  }
  
  /**
   
   - Parameter buffer: buffer description
   */
  init(_ buffer: UnsafeMutableRawBufferPointer) {
    var tempType: UInt32 = 0
    var tempLength: UInt32 = 0
    withUnsafeMutableBytes(of: &tempType) { typePtr in
      typePtr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: 0),
                                                      count: MemoryLayout<UInt32>.size))
    }
    withUnsafeMutableBytes(of: &tempLength) { lengthPtr in
      lengthPtr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: MemoryLayout<UInt32>.size),
                                                        count: MemoryLayout<UInt32>.size))
    }
    type = tempType
    length = tempLength
  }
  
  var encodedData: Data {
    var tempType = type
    var tempLength = length
    var data = Data(bytes: &tempType, count: MemoryLayout<UInt32>.size)
    data.append(Data(bytes: &tempLength, count: MemoryLayout<UInt32>.size))
    return data
  }
  
  static var encodedSize: Int {
    return MemoryLayout<UInt32>.size * 2
  }
  
}
