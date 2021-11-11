//
//  VisionTrackingProcessor.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/07/11.
//

import Foundation
import Vision

protocol VisionTrackingProcessorDelegate {
    func displayFrame(_ frame: CVPixelBuffer?, withAffineTransform transform: CGAffineTransform)
    
}

class VisionTrackingProcessor {
    
}
