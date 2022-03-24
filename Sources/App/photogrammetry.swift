//
//  photogrammetry.swift
//  
//
//  Created by Sabrina Bea on 3/16/22.
//

import Metal
import RealityKit
import Vapor
import CoreImage
import CoreVideo

class PhotogrammetryManager {
    private static var _instance: PhotogrammetryManager!
    class var instance: PhotogrammetryManager {
        get {
            if _instance == nil {
                _instance = PhotogrammetryManager()
            }
            return _instance
        }
    }
    
    private var sessionProgressStructs = Dictionary<UUID, PhotogrammetrySessionProgress>()
    
    private init() {}
    
    // Checks to make sure at least one GPU meets the minimum requirements
    // for object reconstruction. At least one GPU must be a "high power"
    // device, which means it has at least 4 GB of RAM, provides
    // barycentric coordinates to the fragment shader, and is running on a
    // Mac with Apple silicon, or on an Intel-based Mac with a discrete GPU.
    private func supportsObjectReconstruction() -> Bool {
        for device in MTLCopyAllDevices() where
            !device.isLowPower &&
             device.areBarycentricCoordsSupported &&
             device.recommendedMaxWorkingSetSize >= UInt64(4e9) {
            return true
        }
        return false
    }

    // Returns `true` if at least one GPU has hardware support for ray tracing.
    // The GPU that supports ray tracing need not be the same GPU that supports
    // object reconstruction.
    private func supportsRayTracing() -> Bool {
        for device in MTLCopyAllDevices() where device.supportsRaytracing {
            return true
        }
        return false
    }

    // Returns `true` if the current hardware supports Object Capture.
    private func supportsObjectCapture() -> Bool {
        return supportsObjectReconstruction() && supportsRayTracing()
    }

    private func makeUrl(from urlStrComponents: String..., isDirectory: Bool = false) -> URL {
        let directory = DirectoryConfiguration.detect()
        
        var url = URL(fileURLWithPath: directory.workingDirectory)
        
        for (index, urlStrComponent) in urlStrComponents.enumerated() {
            url.appendPathComponent(urlStrComponent, isDirectory: isDirectory || index != urlStrComponents.count - 1)
        }
        
        return url
    }
    
    public func startObjectCapture(_ files: [File]) async -> UUID? {
        let id = startSession(files)
        if let id = id {
            Task {
                guard let _ = await doPhotogrammetry(id) else {
                    print("NIL RESULT RETURNED FROM SESSION \(id)")
                    return
                }
            }
        }
        return id
    }

    public func startSession(_ files: [File]) -> UUID? {
        let id = UUID()
        guard supportsObjectCapture() else {
            print("Object capture not available")
            return nil
        }
        
        let inputFolderUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(id.uuidString, isDirectory: true)
        guard let _ = try? FileManager.default.createDirectory(atPath: inputFolderUrl.path, withIntermediateDirectories: true, attributes: nil) else { return nil }
        for file in files {
            let fileUrl = inputFolderUrl.appendingPathComponent(file.filename)
            guard let _ = try? Data(buffer: file.data).write(to: fileUrl) else { return nil }
        }
        
        
        guard let session = try? PhotogrammetrySession(input: inputFolderUrl) else { return nil }
        
        sessionProgressStructs[id] = PhotogrammetrySessionProgress(session: session)
        return id
    }
    
    public func getProgress(_ id: UUID) -> PhotogrammetrySessionProgress? {
        return sessionProgressStructs[id]
    }
    
    public func doPhotogrammetry(_ id: UUID) async -> PhotogrammetrySession.Result? {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(id.uuidString).usdz")
        let request = PhotogrammetrySession.Request.modelFile(url: url, detail: .full)
        sessionProgressStructs[id]!.fileUrl = url
        let session = sessionProgressStructs[id]!.session
        
        guard ((try? session.process(requests: [request])) != nil) else {
            return nil
        }
        
        do {
            for try await output in session.outputs {
                // TODO: Handle other cases of output?
                switch output {
                case .requestError(_, let error):
                    print("Output: ERROR = \(String(describing: error))")
                    sessionProgressStructs[id]!.error = error
                    return nil
                case .requestComplete(_, let result):
                    sessionProgressStructs[id]!.progress = 100
                    sessionProgressStructs[id]!.result = result
                    return result
                case .requestProgress(_, fractionComplete: let fraction):
                    sessionProgressStructs[id]!.progress = UInt(fraction * 100)
                default:
                    break
                }
            }
        } catch {
            return nil
        }
        
        return nil
    }
}
