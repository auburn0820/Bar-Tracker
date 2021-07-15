//
//  TrackingViewModel.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/06/29.
//

import Foundation
import AVFoundation
import Darwin
import SwiftUI
import Vision

class TrackingViewModel: ObservableObject {
    @Published var videoFrame: UIImage?
    
    private var imageSize: CGSize?
    private var renderer: UIGraphicsImageRenderer?
    private var lines: [CGPoint] = []
    private var polyRect = [TrackedPolyRect]()
    private var objectsToTrack: [TrackedPolyRect] = [TrackedPolyRect]()
    
    private var videoAsset: AVAsset?
    private var videoAssetReaderOutput: AVAssetReaderTrackOutput!
    private var assetReader: AVAssetReader!
    private var videoTrack: AVAssetTrack!
    
    func setVideoAsset(video: AVAsset) {
        self.videoAsset = video
    }
    
    func displayFirstVideoFrame() {
        guard let videoAsset = self.videoAsset else { return }
        let videoImageGenerator = AVAssetImageGenerator(asset: videoAsset)
        videoImageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
        
        do {
            let cgImage = try videoImageGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            if let thumbnail = adjustImageToScreen(imageToResize: uiImage) {
                self.videoFrame = thumbnail
            }
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func setVideoTrack() {
        guard let video = self.videoAsset else { return }
        
        let array = video.tracks(withMediaType: AVMediaType.video)
        self.videoTrack = array[0]
        
        do {
            self.assetReader = try AVAssetReader(asset: video)
        } catch {
            print("Failed to create AVAssetReader: \(error.localizedDescription)")
            return
        }
        
        self.videoAssetReaderOutput = AVAssetReaderTrackOutput(track: self.videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
        
        guard self.videoAssetReaderOutput != nil else {
            return
        }
        
        self.videoAssetReaderOutput.alwaysCopiesSampleData = true
        
        guard self.assetReader.canAdd(videoAssetReaderOutput) else {
            return
        }
        
        self.assetReader.add(videoAssetReaderOutput)
        
        guard self.assetReader.startReading() else { return }
    }
    
    func adjustImageToScreen(imageToResize image: UIImage) -> UIImage? {
        let size = image.size
        let width = UIScreen.main.bounds.width
        
        let widthRatio = width / size.width
        let height = size.height * widthRatio
        
        let newSize = CGSize(width: width, height: height)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.imageSize = newSize
        
        return newImage
    }
    
    func drawLines() {
        guard let size = self.imageSize else { return }
        self.renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer?.image { ctx in
            ctx.cgContext.saveGState()
            ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
            ctx.cgContext.setLineWidth(2)
            
            if self.lines.count > 2 {
                for i in 0..<self.lines.count - 1 {
                    let previous = lines[i]
                    ctx.cgContext.move(to: previous)
                    let current = lines[i + 1]
                    ctx.cgContext.addLine(to: current)
                }
            }
            
            ctx.cgContext.drawPath(using: .fillStroke)
            ctx.cgContext.strokePath()
            ctx.cgContext.restoreGState()
        }
        
        self.videoFrame = image
    }
    
    func nextFrame() -> CVPixelBuffer? {
        guard let sampleBuffer = self.videoAssetReaderOutput.copyNextSampleBuffer() else {
            return nil
        }
        
        return CMSampleBufferGetImageBuffer(sampleBuffer)
    }
    
    func performTracking() {
        var inputObservations = [UUID: VNDetectedObjectObservation]()
        var trackedObjects = [UUID: TrackedPolyRect]()
        
        for object in self.objectsToTrack {
            let inputObservation = VNDetectedObjectObservation(boundingBox: object.boundingBox)
            inputObservations[inputObservation.uuid] = inputObservation
            trackedObjects[inputObservation.uuid] = object
        }
        
        let requestHandler = VNSequenceRequestHandler()
        var trackingFailedForAtLeastOneObject = false
        
        while true {
            guard let frame = self.nextFrame() else {
                break
            }
            
            var rects = [TrackedPolyRect]()
            var line = CGPoint()
            var trackingRequests = [VNRequest]()
            
            for inputObservation in inputObservations {
                let request = VNTrackObjectRequest(detectedObjectObservation: inputObservation.value)
                request.trackingLevel = .accurate
                trackingRequests.append(request)
            }
            
            do {
                try requestHandler.perform(trackingRequests, on: frame)
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
                line = getMidPoint(rect: TrackedPolyRect(observation: observation, color: knownRect.color, style: rectStyle))
                inputObservations[observation.uuid] = observation
            }
            
            self.displayFrame(frame, withAffineTransform: self.videoTrack.preferredTransform.inverted(), rects: rects, line: line)
            
            usleep(useconds_t(self.videoTrack.nominalFrameRate * 1000.0))
        }
        
        self.displayFirstVideoFrame()
        
        if trackingFailedForAtLeastOneObject {
            print("Object tracking failed")
            return
        }
    }
    
    func displayFrame(_ frame: CVPixelBuffer?, withAffineTransform transform: CGAffineTransform, rects: [TrackedPolyRect]?, line: CGPoint) {
        DispatchQueue.main.async {
            if let frame = frame {
                let ciImage = CIImage(cvImageBuffer: frame).transformed(by: transform)
                let uiImage = UIImage(ciImage: ciImage)
                self.videoFrame = uiImage
            }
            
            self.lines.append(line)
            self.polyRect = rects ?? self.objectsToTrack
            self.drawLines()
        }
    }
    
    func getMidPoint(rect: TrackedPolyRect) -> CGPoint {
        let midX = (rect.bottomLeft.x + rect.bottomRight.x) / 2
        let midY = (rect.bottomLeft.y + rect.topLeft.y) / 2
        
        return CGPoint(x: midX, y: midY)
    }
}
