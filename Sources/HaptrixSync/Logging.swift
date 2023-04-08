//
//  Logging.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import os.log

extension OSLog {

  static var frameworkSystem = "com.haptrixSync.package"

  static let player = OSLog(subsystem: frameworkSystem, category: "Player")
  static let io = OSLog(subsystem: frameworkSystem, category: "IO")
  static let network = OSLog(subsystem: frameworkSystem, category: "Network")
}
