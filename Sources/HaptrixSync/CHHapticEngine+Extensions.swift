//
//  HapticPlayer.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import CoreHaptics
import Combine
import os.log

extension CHHapticEngine {
  
  /**
   If you wish to initiate the streaming service before the first play of an AHAP file, call this method
   */
  public func prepareSyncing() {
    let _ = Networking.shared
  }
  
  /**
   Play a pattern, will check for and use any updated AHAP files synced from the Haptrix macOS App
   
   The URL to the AHAP file may change internally if a later file was synced from the Haptrix macOS App
   
   - Parameters:
   - url: URL to AHAP file to play
   - syncUpdates: Should we check for synced updates?
   - Throws: If the operation fails, this will be set to a valid Error describing the error.
   */
  public func playPattern(from url: URL, syncUpdates: Bool) throws {
    
    // Find the correct URL to load from
    let newURL = updatedURL(from: url, syncUpdates: syncUpdates)
    
    try self.playPattern(from: newURL)
  }
  
  /**
   Play a pattern, will check for and use any updated AHAP files synced from the Haptrix macOS App
   
   The URL to the AHAP file may change internally if a later file was synced from the Haptrix macOS App
   
   - Parameters:
   - url: URL to AHAP file to play
   - syncUpdates: Should we check for synced updates?
   - Returns: Boolean if the AHAP was played successfully
   */
  public func playPatternPublisher(from url: URL, syncUpdates: Bool) -> AnyPublisher<Bool, Error> {
    
    let newURL = updatedURL(from: url, syncUpdates: syncUpdates)
    
    return Future { promise in
      
      do {
        try self.playPattern(from: newURL)
        
        self.notifyWhenPlayersFinished(finishedHandler: { (error) -> CHHapticEngine.FinishedAction in
          promise(.success(error == nil))
          return .leaveEngineRunning
        })
      } catch (let error) {
        os_log("Play local error: %@", log: .player, type: .error, "\(error)")
        promise(.failure(error))
      }
      
    }.eraseToAnyPublisher()
    
  }
  
}

extension CHHapticEngine {
  
  /**
   If the sync service is activated, we look for an updated AHAP file
   
   Failing to find an updated file, we fall back to the passed in url
   
   - Parameters:
     - url: URL to the AHAP file
     - syncUpdates: Should we check for synced updates?
   - Returns: URL to either the latest AHAP or the passed in AHAP
   */
  fileprivate func updatedURL(from url: URL, syncUpdates: Bool) -> URL {
    
    // Should we ignore updates and use the one embedded in the bundle?
    guard syncUpdates else {
      return url
    }
    
    let _ = Networking.shared
    
    let fileName = url.deletingPathExtension().lastPathComponent
    
    let io = HaptrixIO()
    
    let folderURL = io.getFileInDocumentsFolder(fileName: fileName)
    
    guard let newFileURL = io.findAHAPInFolder(url: folderURL) else {
      return url
    }
    
    return newFileURL
    
  }
  
}
