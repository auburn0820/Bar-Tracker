//
//  TrackingViewController.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/07/06.
//

import Foundation
import SwiftUI
import UIKit
import AVFoundation

struct TrackingViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let trackingViewController = UITrackingViewController()
        
        return trackingViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

class UITrackingViewController: UIViewController {
    enum State {
        case tracking
        case stopped
    }
    
    private var visionProcessor: VisionTrackerProcessor!
    private var workQueue = DispatchQueue(label: "Suyeong.Bar-Tracker", qos: .userInitiated)
    private var trackedObjectType: TrackedObjectType = .object
    private var objectsToTrack = [TrackedPolyRect]()
    private var state: State = .stopped {
        didSet {
//            self.handleStateChange()
        }
    }
    
    private func displayFirstVideoFrame() {
        do {
            try visionProcessor.readAndDisplayFirstFrame(performRectanglesDetection: false)
        } catch {
//            self.handleError(error)
        }
    }
    
    private func startTracking() {
        do {
            try visionProcessor.performTracking()
        } catch {
//            self.handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            var title: String
            var message: String
            if let processorError = error as? VisionTrackerProcessorError {
                title = "Vision Processor Error"
                switch processorError {
                case .firstFrameReadFailed:
                    message = "Cannot read the first frame from selected video."
                case .objectTrackingFailed:
                    message = "Tracking of one or more objects failed."
                case .readerInitializationFailed:
                    message = "Cannot create a Video Reader for selected video."
                case .rectangleDetectionFailed:
                    message = "Rectangle Detector failed to detect rectangles on the first frame of selected video.e"
                }
            } else {
                title = "Error"
                message = error.localizedDescription
            }
            print(message)
        }
    }
    
    private func handleStateChange() {
        
    }
}
