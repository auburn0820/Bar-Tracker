//
//  VisionTrackingProcessor.swift
//  Bar Tracker
//
//  Created by νΌμμ on 2021/07/11.
//

import Foundation
import Vision

protocol VisionTrackingProcessorDelegate {
    func displayFrame(_ frame: CVPixelBuffer?, withAffineTransform transform: CGAffineTransform)
    
}

class VisionTrackingProcessor {
    
}
