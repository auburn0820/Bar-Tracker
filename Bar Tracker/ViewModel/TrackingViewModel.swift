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
import Combine

class TrackingViewModel: ObservableObject {
    @Published var videoFrame: UIImage?
    @Published var isFinished: Bool = false
    
    private var image: UIImage? {
        didSet {
            self.videoFrame = image
        }
    }
    private var imageSize: CGSize?
    private var renderer: UIGraphicsImageRenderer?
    private var lines = [CGPoint]()
    private var polyRect: TrackedPolyRect?
    private var videoAsset: AVAsset?
    private var frameCounter = PassthroughSubject<UIImage, Never>()
    private var frameSubscriber: AnyCancellable?
    
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
    var rubberbandingNormalized: CGRect {
        guard let imageSize = self.imageSize else {
            return CGRect.zero
        }
        
        var rect = rubberbandingRect
        
        rect.origin.x = rect.origin.x / imageSize.width
        rect.origin.y = rect.origin.y / imageSize.height
        rect.size.width /= imageSize.width
        rect.size.height /= imageSize.height
        // Adjust to Vision.framework input requrement - origin at LLC
        rect.origin.y = 1.0 - rect.origin.y - rect.size.height
        
        return rect
    }
    
    func setObjectToTrack() {
        let rect = self.rubberbandingNormalized
        self.polyRect = TrackedPolyRect(cgRect: rect, color: UIColor.green)
    }
    
    func setVideoAsset(video: AVAsset) {
        self.videoAsset = video
    }
    
    func setFrameSubscriber() {
        frameSubscriber = frameCounter
            .throttle(for: 1, scheduler: DispatchQueue.global(qos: .background), latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.videoFrame = image
            }
    }
    
    func convertSampleBufferToUIImage(cvPixelBuffer frame: CVPixelBuffer, transform: CGAffineTransform) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: frame).transformed(by: transform)
        
        let ctx = CIContext(options: nil)
        guard let cgImage = ctx.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        return uiImage
    }
    
    func displayFirstVideoFrame() {
        guard let videoAsset = self.videoAsset else {
            print("Can't read video asset.")
            return
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: videoAsset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let firstFrame = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 600), actualTime: nil)
            let uiImage = UIImage(cgImage: firstFrame)
            self.image = adjustImageToScreen(imageToResize: uiImage)
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func adjustImageToScreen(imageToResize image: UIImage) -> UIImage? {
        let size = image.size
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if size.width > size.height {
            newWidth = UIScreen.main.bounds.width
            newHeight = size.height * (newWidth / size.width)
            
            if(newHeight > UIScreen.main.bounds.height) {
                newWidth = newWidth * (UIScreen.main.bounds.width / newHeight)
                newHeight = UIScreen.main.bounds.height
            }
        } else {
            newHeight = UIScreen.main.bounds.height
            newWidth = size.width * (newHeight / size.height)
            
            if(newWidth > UIScreen.main.bounds.width) {
                newHeight = newHeight * (UIScreen.main.bounds.width / newWidth)
                newWidth = UIScreen.main.bounds.width
            }
        }
        
        let newSize = CGSize(width: newWidth, height: newHeight)
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
        
        removeZeroLine()
        
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
        
        
        ctx.setStrokeColor(UIColor.green.cgColor)
        if let polyRect = self.polyRect {
            let cornerPoints = polyRect.cornerPoints
            var previous = scaleRect(cornerPoint: cornerPoints[cornerPoints.count - 1])

            for cornerPoint in cornerPoints {
                ctx.move(to: previous)
                let current = scaleRect(cornerPoint: cornerPoint)
                ctx.addLine(to: current)
                previous = current
            }
        }
        
        if self.lines.count > 2 {
            for i in 0..<self.lines.count - 1 {
                let previous = scaleLine(line: lines[i])
                ctx.move(to: previous)
                let current = scaleLine(line: lines[i + 1])
                ctx.addLine(to: current)
            }
        }
        
        ctx.strokePath()
        ctx.restoreGState()
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = newImage {
            self.videoFrame = image
        }
    }
    
    private func removeZeroLine() {
        for i in 0..<self.lines.count {
            if lines[i].x == 1.0 || lines[i].y == 1.0 {
                lines.remove(at: i)
            }
        }
    }
    
    func performTracking() {
        guard let videoAsset = self.videoAsset else {
            print("Can't read video asset.")
            return
        }
        guard let videoReader = VideoReader(videoAsset: videoAsset) else {
            print("Can't initialize VideoReader.")
            return
        }
        
        var inputObservations = [UUID: VNDetectedObjectObservation]()
        var trackedObjects = [UUID: TrackedPolyRect]()
        
        guard let rect = self.polyRect else {
            return
        }
        
        let inputObservation = VNDetectedObjectObservation(boundingBox: rect.boundingBox)
        inputObservations[inputObservation.uuid] = inputObservation
        trackedObjects[inputObservation.uuid] = rect
        
        let requestHandler = VNSequenceRequestHandler()
        
        DispatchQueue.global(qos: .userInitiated).async {
            while !self.isFinished {
                guard let frame = videoReader.nextFrame() else {
                    break
                }
                
                var rects = [TrackedPolyRect]()
                var line = CGPoint()
                var request: VNTrackingRequest!
                
                for inputObservation in inputObservations {
                    request = VNTrackObjectRequest(detectedObjectObservation: inputObservation.value)
                    request.trackingLevel = .accurate
                }
                
                do {
                    try requestHandler.perform([request], on: frame, orientation: videoReader.orientation)
                } catch {
                    print(error.localizedDescription)
                }
                
                guard let result = request.results as? [VNObservation] else {
                    continue
                }
                
                guard let observation = result.first as? VNDetectedObjectObservation else {
                    continue
                }
                
                let rectStyle: TrackedPolyRectStyle = observation.confidence > 0.5 ? .solid : .dashed
                let knownRect = trackedObjects[observation.uuid]!
                
                let rectToAppend = TrackedPolyRect(observation: observation, color: knownRect.color, style: rectStyle)
                
                rects.append(rectToAppend)
                line = self.getRectMidPoint(rect: rectToAppend)
                
                self.lines.append(line)
                self.polyRect = rectToAppend
                
                inputObservations[observation.uuid] = observation
                
                self.displayFrame(frame, withAffineTransform: videoReader.affineTransform)
                usleep(useconds_t(videoReader.frameRateInSeconds))
            }
        }
    }
    
    func displayFrame(_ frame: CVPixelBuffer?, withAffineTransform transform: CGAffineTransform) {
        DispatchQueue.main.async {
            if let frame = frame {
                guard let uiImage = self.convertSampleBufferToUIImage(cvPixelBuffer: frame, transform: transform) else {
                    return
                }
                self.image = self.adjustImageToScreen(imageToResize: uiImage)
                self.rubberbandingVector = .zero
                self.rubberbandingStart = .zero
                self.drawLinesAndRectangle(isTouchesEnded: true)
            }
        }
    }
    
    func getRectMidPoint(rect: TrackedPolyRect) -> CGPoint {
        let midX = (rect.bottomLeft.x + rect.bottomRight.x) / 2
        let midY = (rect.bottomLeft.y + rect.topLeft.y) / 2
        
        return CGPoint(x: midX, y: midY)
    }
    
    func handleDragging(value: DragGesture.Value, isDragStart: inout Bool, state: GestureState) {
        switch state {
        case .onChanged:
            if isDragStart {
                self.rubberbandingStart = value.startLocation
                isDragStart.toggle()
            } else {
                self.rubberbandingStart.applying(CGAffineTransform(translationX: value.translation.width, y: value.translation.height))
            }
            self.rubberbandingVector = CGPoint(x: value.translation.width, y: value.translation.height)
            self.drawLinesAndRectangle(isTouchesEnded: false)
        case .onEnded:
            self.setObjectToTrack()
            isDragStart.toggle()
            self.drawLinesAndRectangle(isTouchesEnded: true)
        }
    }
    
    private func scaleRect(cornerPoint point: CGPoint) -> CGPoint {
        // Adjust bBox from Vision.framework coordinate system (origin at LLC) to imageView coordinate system (origin at ULC)
        let pointY = 1.0 - point.y
        guard let scaleFactor = self.imageSize else {
            return CGPoint.zero
        }
        
        return CGPoint(x: point.x * scaleFactor.width, y: pointY * scaleFactor.height)
    }
    
    private func scaleLine(line: CGPoint) -> CGPoint {
        let pointY = 1.0 - line.y
        guard let scaleFactor = self.imageSize else {
            return CGPoint.zero
        }
        
        return CGPoint(x: line.x * scaleFactor.width, y: pointY * scaleFactor.height)
    }
}

enum GestureState {
    case onChanged
    case onEnded
}
