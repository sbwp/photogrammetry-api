//
//  photogrammetry.swift
//  
//
//  Created by Sabrina Bea on 3/16/22.
//

import Metal
import RealityKit
import Vapor

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

public func doObjectCapture() async -> PhotogrammetrySession.Result? {
    guard supportsObjectCapture() else {
        print("Object capture not available")
        return nil
    }
    
//    let inputFolderUrl = makeUrl(from: "car", isDirectory: true) // TODO: image location
    let inputFolderUrl = makeUrl(from: "InputImages", isDirectory: true) // TODO: image location
    let url = makeUrl(from: "MyObject.usdz") // TODO: Output location
    let request = PhotogrammetrySession.Request.modelFile(url: url, detail: .preview)
    guard let session = try? PhotogrammetrySession(input: inputFolderUrl) else { return nil }
    
    guard ((try? session.process(requests: [request])) != nil) else {
        return nil
    }
    
    do {
        for try await output in session.outputs {
            // TODO: Handle other cases of output?
            switch output {
                case .requestError(let request, let error):
                    print("Output: ERROR = \(String(describing: error))")
                    return nil
                case .requestComplete(let request, let result):
                    return result
                default:
                    break
            }
        }
    } catch {
        return nil
    }
    
    return nil
}
