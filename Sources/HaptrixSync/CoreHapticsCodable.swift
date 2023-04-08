//
//  HapticCodable.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import Foundation

/**
 This file represents a minimal codable conformance to an AHAP file
 */

class HapticBase: Codable {

}

// MARK: - Generic Parameter

class HapticEventParameter: NSObject, Codable {

  var value: NSNumber! = 0
  var parameterID: String? = ""

  // MARK: - Codable

  enum CodingKeys: String, CodingKey {
    case parameterID = "ParameterID"
    case value = "ParameterValue"
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    parameterID = try values.decodeIfPresent(String.self, forKey: .parameterID)
    value = try values.decode(Float.self, forKey: .value) as NSNumber
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(parameterID, forKey: .parameterID)
    try container.encode(value.floatValue, forKey: .value)
  }

}

// MARK: - Parameter Curve Control

class ParameterCurveControlPoint: NSObject, Codable {
  var time: NSNumber! = 0
  var value: NSNumber! = 0

  // MARK: - Codable

  enum CodingKeys: String, CodingKey {
    case time = "Time"
    case value = "ParameterValue"
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    time = try values.decode(TimeInterval.self, forKey: .time) as NSNumber
    value = try values.decode(Float.self, forKey: .value) as NSNumber
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(time.floatValue, forKey: .time)
    try container.encode(value.floatValue, forKey: .value)
  }
}

// MARK: - Parameter Curve

class HapticParameterCurve: HapticBase {
  var time: NSNumber! = 0
  var parameterID: String?
  var controlPoints: [ParameterCurveControlPoint] = []

  // MARK: - Codable

  enum CodingKeys: String, CodingKey {
    case parameterID = "ParameterID"
    case time = "Time"
    case controlPoints = "ParameterCurveControlPoints"
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    parameterID = try values.decodeIfPresent(String.self, forKey: .parameterID)
    time = try values.decodeIfPresent(TimeInterval.self, forKey: .time) as NSNumber?
    self.controlPoints = try values.decodeIfPresent([ParameterCurveControlPoint].self, forKey: .controlPoints) ?? []
    self.controlPoints.sort { (lhs, rhs) -> Bool in
      lhs.time.floatValue < rhs.time.floatValue
    }

    super.init()
  }

  override func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(parameterID, forKey: .parameterID)
    try container.encode(time?.doubleValue, forKey: .time)
    try container.encode(controlPoints, forKey: .controlPoints)
  }
}

// MARK: - Event

class HapticEvent: HapticBase {

  var eventParameters: [HapticEventParameter]?

  var time: NSNumber! = 0
  var duration: NSNumber! = 0
  var waveForm: URL?
  var eventType: String?

  // MARK: - Codable

  enum CodingKeys: String, CodingKey {
    case time = "Time"
    case duration = "EventDuration"
    case eventType = "EventType"
    case eventParameters = "EventParameters"
    case waveformPath = "EventWaveformPath"
    case waveformData = "EventWaveformData"
  }

  required init(from decoder: Decoder) throws {
    super.init()

    let values = try decoder.container(keyedBy: CodingKeys.self)

    time = try values.decodeIfPresent(TimeInterval.self, forKey: .time) as NSNumber?
    duration = try values.decodeIfPresent(TimeInterval.self, forKey: .duration) as NSNumber?
    eventType = try values.decodeIfPresent(String.self, forKey: .eventType)
    eventParameters = try values.decodeIfPresent([HapticEventParameter].self, forKey: .eventParameters)
    waveForm = try values.decodeIfPresent(URL.self, forKey: .waveformPath)
  }

  override func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(time?.doubleValue, forKey: .time)
    try container.encodeIfPresent(duration?.doubleValue, forKey: .duration)
    try container.encode(eventType, forKey: .eventType)
    try container.encodeIfPresent(eventParameters?.filter({ $0.value != nil }), forKey: .eventParameters)
    try container.encodeIfPresent(waveForm, forKey: .waveformPath)
  }
}

// MARK: - Pattern

class CoreHapticsCodable: NSObject, Codable {

  var pattern: [HapticBase] = []

  // MARK: - Codable

  enum CodingKeys: String, CodingKey {
    case pattern = "Pattern"
  }

  enum NestedCodingKeys: String, CodingKey {
    case event = "Event"
    case parameterCurve = "ParameterCurve"
    case parameter = "Parameter"
  }

  enum OperationTypes: String, Decodable {
    case event = "Event"
    case parameterCurve = "ParameterCurve"
  }

  required init(from decoder: Decoder) throws {
    super.init()

    let values = try decoder.container(keyedBy: CodingKeys.self)

    pattern = []

    var patternArray = try values.nestedUnkeyedContainer(forKey: .pattern)

    while !patternArray.isAtEnd {
      let operation = try patternArray.nestedContainer(keyedBy: NestedCodingKeys.self)

      if let event = try operation.decodeIfPresent(HapticEvent.self, forKey: NestedCodingKeys.event) {
        pattern.append(event)
      } else if let curve = try operation.decodeIfPresent(HapticParameterCurve.self, forKey: NestedCodingKeys.parameterCurve) {
        pattern.append(curve)
      }
    }

  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    var patternArray = container.nestedUnkeyedContainer(forKey: .pattern)
    for item in pattern {
      var operation = patternArray.nestedContainer(keyedBy: NestedCodingKeys.self)
      if let event = item as? HapticEvent {
        try operation.encode(event, forKey: NestedCodingKeys.event)
      }
      if let curve = item as? HapticParameterCurve {
        try operation.encode(curve, forKey: NestedCodingKeys.parameterCurve)
      }
    }

  }

}
