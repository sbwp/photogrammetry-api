//
//  PhotogrammetrySessionProgress.swift
//  
//
//  Created by Sabrina Bea on 3/17/22.
//

import Foundation
import RealityKit


struct PhotogrammetrySessionProgress {
    var session: PhotogrammetrySession
    var progress: UInt = 0
    var result: PhotogrammetrySession.Result? = nil
    var fileUrl: URL? = nil
    var error: Error? = nil
}
