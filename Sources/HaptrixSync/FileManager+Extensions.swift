//
//  FileManager+Extensions.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com.
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import Foundation

extension FileManager {
  
  /**
   Delete the contents of a folder
   - Parameter url: The content inside this URL will be deleted
   */
  func deleteContentsOfFolder(at url: URL) {
    let fileManager = FileManager.default
    let urls = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .includesDirectoriesPostOrder)
    
    for url in urls ?? [] {
      try? fileManager.removeItem(at: url)
    }
  }
  
}
