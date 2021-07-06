//
//  VisionProcessor.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/07/06.
//

import AVFoundation
import UIKit
import Vision

enum VisionTrackerProcessorError: Error {
    case readerInitializationFailed
    case firstFrameReadFailed
    case objectTrackingFailed
    case rectangleDetectionFailed
}

protocol VisiontrackerProcessorDelegate: AnyObject {
    func displayFrame(_ frame: CVPixelBuffer?,
                      withAffineTransform transform: CGAffineTransform,
                      rects: [TrackedPolyRect]?,
                      line: CGPoint)
    func displayFrameCounter(_ frame: Int)
    func didFinishTracking()
}

class VisionTrackerProcessor {
    var videoAsset: AVAsset!
    var trackingLevel = VNRequestTrackingLevel.accurate
    var objectsToTrack = [TrackedPolyRect]()
    weak var delegate: VisiontrackerProcessorDelegate?
    
    private var cancelRequested = false
    private var initialRectObservations = [VNRectangleObservation]()
    
    init(videoAsset: AVAsset) {
        self.videoAsset = videoAsset
    }
    
    func readAndDisplayFirstFrame(performRectanglesDetection: Bool) throws {
        guard let videoReader = VideoReader(videoAsset: self.videoAsset) else {
            throw VisionTrackerProcessorError.readerInitializationFailed
        }
        guard let firstFrame = videoReader.nextFrame() else {
            throw VisionTrackerProcessorError.firstFrameReadFailed
        }
        
        var firstFrameRects: [TrackedPolyRect]? = nil
        if performRectanglesDetection {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: firstFrame,
                                                            orientation: videoReader.orientation,
                                                            options: [:])
            let rectangleDetectionRequest = VNDetectRectanglesRequest()
            rectangleDetectionRequest.minimumAspectRatio = VNAspectRatio(0.2)
            rectangleDetectionRequest.maximumAspectRatio = VNAspectRatio(1.0)
            rectangleDetectionRequest.minimumSize = Float(0.1)
            rectangleDetectionRequest.maximumObservations = Int(10)
            
            do {
                try imageRequestHandler.perform([rectangleDetectionRequest])
            } catch {
                throw VisionTrackerProcessorError.rectangleDetectionFailed
            }
            
            if let rectObservations = rectangleDetectionRequest.results as? [VNRectangleObservation] {
                initialRectObservations = rectObservations
                var detectedRects = [TrackedPolyRect]()
                for (index, rectangleObservation) in initialRectObservations.enumerated() {
                    let rectColor = TrackedObjectsPalette.color(atIndex: index)
                    detectedRects.append(TrackedPolyRect(observation: rectangleObservation, color: rectColor))
                }
                firstFrameRects = detectedRects
            }
        }
        
        delegate?.displayFrame(firstFrame,
                               withAffineTransform: videoReader.affineTransform,
                               rects: firstFrameRects,
                               line: CGPoint())
    }
    
    func performTracking() throws {
        guard let videoReader = VideoReader(videoAsset: self.videoAsset) else {
            throw VisionTrackerProcessorError.readerInitializationFailed
        }
        
        guard videoReader.nextFrame() != nil else {
            throw VisionTrackerProcessorError.firstFrameReadFailed
        }
        
        self.cancelRequested = false
        
        var inputObservations = [UUID: VNDetectedObjectObservation]()
        var trackedObjects = [UUID: TrackedPolyRect]()
        
        for rect in self.objectsToTrack {
            let inputObservation = VNDetectedObjectObservation(boundingBox: rect.boundingBox)
            inputObservations[inputObservation.uuid] = inputObservation
            trackedObjects[inputObservation.uuid] = rect
        }
        let requestHandler = VNSequenceRequestHandler()
        var trackingFailedForAtLeastOneObject = false
        
        while true {
            guard cancelRequested == false, let frame = videoReader.nextFrame() else {
                break
            }
            
            var rects = [TrackedPolyRect]()
            var line = CGPoint()
            var trackingRequests = [VNRequest]()
            for inputObservation in inputObservations {
                let request: VNTrackingRequest!
                request = VNTrackObjectRequest(detectedObjectObservation: inputObservation.value)
                request.trackingLevel = self.trackingLevel
                trackingRequests.append(request)
            }
            
            do {
                try requestHandler.perform(trackingRequests, on: frame, orientation: videoReader.orientation)
            } catch {
                trackingFailedForAtLeastOneObject = true
            }
            
            for processedRequest in trackingRequests {
                guard let results = processedRequest.results as? [VNObservation] else {
                    continue
                }
                guard let observation = results.first as? VNDetectedObjectObservation else {
                    continue
                }
                
                let rectStyle: TrackedPolyRectStyle = observation.confidence > 0.5 ? .solid : .dashed
                let knownRect = trackedObjects[observation.uuid]!
                
                rects.append(TrackedPolyRect(observation: observation, color: knownRect.color, style: rectStyle))
                
                inputObservations[observation.uuid] = observation
            }
            
            delegate?.displayFrame(frame,
                                   withAffineTransform: videoReader.affineTransform,
                                   rects: rects,
                                   line: line)
            
            usleep(useconds_t(videoReader.frameRateInSeconds))
        }
        
        delegate?.didFinishTracking()
        
        if trackingFailedForAtLeastOneObject {
            throw VisionTrackerProcessorError.objectTrackingFailed
        }
    }
    
    func cancelTracking() {
        cancelRequested = true
    }
}
