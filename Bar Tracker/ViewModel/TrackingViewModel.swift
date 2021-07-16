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
    
    private var image: UIImage? {
        didSet {
            self.videoFrame = image
        }
    }
    private var imageSize: CGSize?
    private var renderer: UIGraphicsImageRenderer?
    private var lines = [CGPoint]()
    private var polyRects = [TrackedPolyRect]()
    private var objectsToTrack = [TrackedPolyRect]()
    
    private var videoAsset: AVAsset?
    private var videoAssetReaderOutput: AVAssetReaderTrackOutput!
    private var assetReader: AVAssetReader!
    private var videoTrack: AVAssetTrack!
    
    var rubberbandingStart = CGPoint.zero
    var rubberbandingVector = CGPoint.zero
    var rubberbandingRect: CGRect {
        let pt1 = self.rubberbandingStart
        let pt2 = CGPoint(x: self.rubberbandingStart.x + self.rubberbandingVector.x,
                          y: self.rubberbandingStart.y + self.rubberbandingVector.y)
        let rect = CGRect(x: min(pt1.x, pt2.x),
                          y: min(pt1.y, pt2.y),
                          width: abs(pt1.x - pt2.x),
                          height: abs(pt1.y - pt2.y))
        return rect
    }
//    private var rubberbandingNormalized: CGRect? {
//        guard let imageSize = self.imageSize else {
//            return nil
//        }
//        var rect = self.rubberbandingRect
//        
//        rect.origin.x = (rect.origin.x - self.)
//    }
    
    func setObjectToTrack() {
        let rect = self.rubberbandingRect
        
        self.objectsToTrack.append(TrackedPolyRect(cgRect: rect, color: UIColor.green))
    }
    
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
                self.image = thumbnail
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
    
    func drawLinesAndRectangle(isTouchesEnded: Bool) {
        // 다음 프레임 이미지를 인자로 받아 해당 프레임에 라인과 사각형을 그려줘야 함
        guard let size = self.imageSize else {
            return
        }
        guard let image = self.image else {
            return
        }
        
        UIGraphicsBeginImageContext(size)
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.saveGState()
        ctx.clear(CGRect(origin: .zero, size: size))
        ctx.setLineWidth(2)
        
        image.draw(at: CGPoint.zero)
        
        if self.rubberbandingRect != CGRect.zero {
            if !isTouchesEnded {
                ctx.setStrokeColor(UIColor.blue.cgColor)
                ctx.setLineDash(phase: CGFloat(0.0), lengths: [4.0, 2.0])
                ctx.stroke(self.rubberbandingRect)
            } else {
                ctx.setStrokeColor(UIColor.green.cgColor)
                ctx.stroke(self.rubberbandingRect)
            }
        }
        
        for polyRect in self.polyRects {
            ctx.setStrokeColor(UIColor.green.cgColor)
            let cornerPoints = polyRect.cornerPoints
            var previous = cornerPoints[cornerPoints.count - 1]
            
            for cornerPoint in cornerPoints {
                ctx.move(to: previous)
                let current = cornerPoint
                ctx.addLine(to: current)
                previous = current
            }
        }
        
        if self.lines.count > 2 {
            for i in 0..<self.lines.count - 1 {
                let previous = lines[i]
                ctx.move(to: previous)
                let current = lines[i + 1]
                ctx.addLine(to: current)
            }
        }
        
        ctx.strokePath()
        ctx.restoreGState()
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.videoFrame = newImage
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
//        self.objectsToTrack = self.polyRects
        
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
            
            self.polyRects.removeAll()
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
                self.polyRects.append(TrackedPolyRect(observation: observation, color: knownRect.color, style: rectStyle))
                line = getMidPoint(rect: TrackedPolyRect(observation: observation, color: knownRect.color, style: rectStyle))
                self.lines.append(line)
                inputObservations[observation.uuid] = observation
            }
            
            let ciImage = CIImage(cvPixelBuffer: frame)
            let uiImage = UIImage(ciImage: ciImage)
            self.videoFrame = uiImage
            
//            drawLinesAndRectangle(isTouchesEnded: true)
            
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
            self.polyRects = rects ?? self.objectsToTrack
            self.drawLinesAndRectangle(isTouchesEnded: true)
        }
    }
    
    func getMidPoint(rect: TrackedPolyRect) -> CGPoint {
        let midX = (rect.bottomLeft.x + rect.bottomRight.x) / 2
        let midY = (rect.bottomLeft.y + rect.topLeft.y) / 2
        
        return CGPoint(x: midX, y: midY)
    }
}
