//
//  HaptrixIO.swift
//  HaptrixSync
//
//  Copyright © 2021 nthState, http://www.nthstate.com
//  Released under the MIT License.
//
//  See https://github.com/nthState/HaptrixSync/blob/master/LICENSE for license information.
//

import Combine
import CryptoKit
import Foundation
import os.log
import ZIPFoundation

class HaptrixIO {

}

extension HaptrixIO {

  /**
   Makes an MD5 Hash of Data, for fingerprinting
   
   - Parameter data: The data to take an MD5 hash of
   - Returns: Hash of the data as a string
   */
  private func md5(of data: Data) -> String {
    return Insecure.MD5.hash(data: data)
      .map { String(format: "%02hhx", $0) }
      .joined()
  }

}

extension HaptrixIO {

  /**
   Save data
   
   - Parameter data: data to save
   - Returns: URL where the data was saved
   */
  func save(data: Data) -> AnyPublisher<URL, Error> {

    let fileNameHash = md5(of: data)
    let folderURL = getFileInDocumentsFolder(fileName: fileNameHash)
    let fileNameWithExtension = "\(fileNameHash).zip"

    do {
      try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
    } catch let error {
      os_log("Error: %@", log: .io, type: .error, "Cant create folder structure: \(error)")
      return Result<URL, Error>.Publisher(error).eraseToAnyPublisher()
    }

    FileManager.default.deleteContentsOfFolder(at: folderURL)
    let fileURL = folderURL.appendingPathComponent(fileNameWithExtension)

    do {
      try data.write(to: fileURL, options: .atomic)
    } catch let error {
      os_log("Error: %@", log: .io, type: .error, "Cant write file: \(error)")
      return Result<URL, Error>.Publisher(error).eraseToAnyPublisher()
    }

    return Result<URL, Error>.Publisher(fileURL).eraseToAnyPublisher()
  }

  /**
   Get a URL to the temp directory
   
   - Returns: URLL to the TEMP directory
   */
  fileprivate func getTempDirectory() -> URL {
    return URL(fileURLWithPath: NSTemporaryDirectory())
  }

  /**
   Get a unique file
   
   - Parameter fileName: Name of the folder to create
   - Returns: URL to the new folder
   */
  func getFileInDocumentsFolder(fileName: String) -> URL {
    let tempDirectoryURL = getTempDirectory()
    let temporaryFileURL = tempDirectoryURL
      .appendingPathComponent("Haptrix")
      .appendingPathComponent(fileName)
    return temporaryFileURL
  }

}

extension HaptrixIO {

  enum ExtractError: Error {
    // case cantExtractContents
    case cantFindFile
    // case couldNotDecodeData
  }

  /**
   Extract ZIP file
   
   - Parameter url: URL to zip file
   - Returns: URL to the AHAP file in the extracted folder
   */
  func extract(url: URL) -> AnyPublisher<URL, Error> {

    let folder = url.deletingLastPathComponent()

    do {
      try FileManager.default.unzipItem(at: url, to: folder)

      guard let fileURL = findAHAPInFolder(url: folder) else {
        throw ExtractError.cantFindFile
      }

      let newFolderName = fileURL.deletingPathExtension().lastPathComponent
      let dstFolder = getFileInDocumentsFolder(fileName: newFolderName)

      // Move items to `displayName` folder
      try? FileManager.default.removeItem(at: dstFolder)
      try FileManager.default.copyItem(at: folder, to: dstFolder)

      guard let newFileURL = findAHAPInFolder(url: dstFolder) else {
        throw ExtractError.cantFindFile
      }

      return Just(newFileURL).setFailureType(to: Error.self)
        .eraseToAnyPublisher()

    } catch let error {
      return Result<URL, Error>.Publisher(error)
        .eraseToAnyPublisher()
    }

  }

}

// MARK: - Finding AHAP files

extension HaptrixIO {

  /**
   Find AHAP in file
   
   - Parameter url: The folder in which to search
   - Returns: URL to the AHAP file if it exists
   */
  func findAHAP(url: URL) -> AnyPublisher<URL, Error> {

    do {
      let folder = url.deletingLastPathComponent()
      guard let fileURL = findAHAPInFolder(url: folder) else {
        throw ExtractError.cantFindFile
      }
      return Just(fileURL).setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    } catch {
      os_log("AHAP Error: %@", log: .io, type: .error, "Cant find AHAP: \(error)")
      return Result<URL, Error>.Publisher(error).eraseToAnyPublisher()
    }

  }

  /**
   Find AHAP in file
   
   - Parameter url: The folder in which to search
   - Returns: URL to the AHAP file if it exists
   */
  func findAHAPInFolder(url: URL) -> URL? {

    let directoryContents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    guard let ahapFile = directoryContents?.filter({ $0.pathExtension == "ahap" }).first else {
      return nil
    }
    return ahapFile
  }

}

// MARK: - Waveforms

extension HaptrixIO {

  /**
   Updates any wave form paths to be relative to the app on disk
   
   - Parameter url: URL of AHAP file to update
   - Returns: URL to updated AHAP file
   */
  func updateWaveForms(at url: URL) -> AnyPublisher<URL, Error> {

    let ahapData: Data
    var ahap: CoreHapticsCodable
    do {
      ahapData = try Data(contentsOf: url)
      ahap = try JSONDecoder().decode(CoreHapticsCodable.self, from: ahapData)
      updatePaths(ahapURL: url, ahap: &ahap)
      let newAHAPData = try JSONEncoder().encode(ahap)
      try newAHAPData.write(to: url)

      return Result<URL, Error>.Publisher(url)
        .eraseToAnyPublisher()
    } catch let error {
      return Result<URL, Error>.Publisher(error)
        .eraseToAnyPublisher()
    }

  }

  /**
   Updates any wave form paths to be relative to the app on disk
   
   - Parameters:
   - ahapURL: URL to AHAP file
   - ahap:  AHAP file to update
   */
  func updatePaths(ahapURL: URL, ahap: inout CoreHapticsCodable) {

    let ahapFolder = ahapURL.deletingLastPathComponent()

    for element in ahap.pattern {

      guard let item = element as? HapticEvent else {
        continue
      }

      if let waveForm = item.waveForm {

        let waveFormFileName = waveForm.lastPathComponent
        let newURL = ahapFolder.appendingPathComponent(waveFormFileName)

        item.waveForm = URL(string: newURL.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)
      }

    }
  }

}
