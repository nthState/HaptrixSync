//
//  HaptrixSync.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com.
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import Foundation
import Combine
import os.log

class NetworkDataDelegate {
  
  private var cancellables = Set<AnyCancellable>()
  
  /**
   Saves the data zip from the Haptrix editor to disk
   
   - Parameter data: data received from the server
   */
  func receive(data: Data) {
    
    guard data.count > 0 else {
      return
    }
    
    let io = HaptrixIO()
    
    io.save(data: data)
      .flatMap { io.extract(url: $0) }
      .flatMap { io.updateWaveForms(at: $0) }
      .sink(receiveCompletion: { (result) in
        switch result {
        case .failure(let error):
          os_log("Sync error: %@", log: .io, type: .error, "\(error)")
        case .finished:
          os_log("finished", log: .io, type: .debug)
        }
      }, receiveValue: { value in
        os_log("Data saved", log: .io, type: .debug)
      })
      .store(in: &cancellables)
    
  }
  
}
