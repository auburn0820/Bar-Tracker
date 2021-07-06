//
//  TrackingImageView.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/07/06.
//

import Foundation
import SwiftUI
import UIKit

struct TrackingImageView: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        let trackingImageView = UITrackingImageView()
        
        return trackingImageView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

class UITrackingImageView: UIView {
    var image: UIImage!
    var polyRects = [TrackedPolyRect]()
    var lines = [CGPoint]()
    
    var imageAreaRect = CGRect.zero
    
    let dashedPhase = CGFloat(0.0)
    let dashedLinesLengths: [CGFloat] = [4.0, 2.0]
    
    var rubberbandingStart = CGPoint.zero
    var rubberbandingVector = CGPoint.zero
    var rubberbandingRect: CGRect {
        let pt1 = self.rubberbandingStart
        let pt2 = CGPoint(x: self.rubberbandingStart.x + self.rubberbandingVector.x, y: self.rubberbandingStart.y + self.rubberbandingVector.y)
        let rect = CGRect(x: min(pt1.x, pt2.x), y: min(pt1.x, pt2.y), width: abs(pt1.x - pt2.y), height: abs(pt1.y - pt2.y))
        
        return rect
    }
    
    var rubberbandingNormalized: CGRect {
        guard imageAreaRect.size.width > 0 && imageAreaRect.size.height > 0 else {
            return CGRect.zero
        }
        
        var rect = rubberbandingRect
        
        rect.origin.x = (rect.origin.x - self.imageAreaRect.origin.x) / self.imageAreaRect.size.width
        rect.origin.y = (rect.origin.y - self.imageAreaRect.origin.y) / self.imageAreaRect.size.height
        rect.size.width /= self.imageAreaRect.size.width
        rect.size.height /= self.imageAreaRect.size.height
        
        rect.origin.y = 1.0 - rect.origin.y - rect.size.height
        
        return rect
    }
    
    func isPointWithinDrawingArea(_ locationInView: CGPoint) -> Bool {
        return self.imageAreaRect.contains(locationInView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.saveGState()
        ctx.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        ctx.setLineWidth(2.0)
        
        guard let newImage = scaleImage(to: rect.size) else {
            return
        }
        
        newImage.draw(at: self.imageAreaRect.origin)
        
        if self.rubberbandingRect != CGRect.zero {
            ctx.setStrokeColor(UIColor.blue.cgColor)
            ctx.setLineDash(phase: dashedPhase, lengths: dashedLinesLengths)
            ctx.stroke(self.rubberbandingRect)
        }
        
        for polyRect in self.polyRects {
            ctx.setStrokeColor(polyRect.color.cgColor)
            switch polyRect.style {
            case .solid:
                ctx.setLineDash(phase: dashedPhase, lengths: [])
            case .dashed:
                ctx.setLineDash(phase: dashedPhase, lengths: dashedLinesLengths)
            }
            let cornerPoints = polyRect.cornerPoints
            var previous = scale(cornerPoint: cornerPoints[cornerPoints.count - 1], toImageViewPointInViewRect: rect)
            for cornerPoint in cornerPoints {
                ctx.move(to: previous)
                let current = scale(cornerPoint: cornerPoint, toImageViewPointInViewRect: rect)
                ctx.addLine(to: current)
                previous = current
            }
        }
        
        // 라인 그려주는 코드 생성하기
    }
    
    private func scaleImage(to viewSize: CGSize) -> UIImage? {
        guard self.image != nil && self.image.size != CGSize.zero else {
            return nil
        }
        
        self.imageAreaRect = CGRect.zero
        
        let imageAspectRatio = self.image.size.width / self.image.size.height
        
        let imageSizeOption1 = CGSize(width: viewSize.width, height: floor(viewSize.width / imageAspectRatio))
        if imageSizeOption1.height <= viewSize.height {
            let imageX: CGFloat = 0
            let imageY = floor((viewSize.height - imageSizeOption1.height) / 2.0)
            self.imageAreaRect = CGRect(x: imageX,
                                        y: imageY,
                                        width: imageSizeOption1.width,
                                        height: imageSizeOption1.height)
        }
        
        if self.imageAreaRect == CGRect.zero {
            let imageSizeOption2 = CGSize(width: floor(viewSize.height * imageAspectRatio),
                                          height: viewSize.height)
            if imageSizeOption2.width <= viewSize.width {
                let imageX = floor((viewSize.width - imageSizeOption2.width) / 2.0)
                let imageY: CGFloat = 0
                self.imageAreaRect = CGRect(x: imageX,
                                            y: imageY,
                                            width: imageSizeOption2.width,
                                            height: imageSizeOption2.height)
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(self.imageAreaRect.size, false, 0.0)
        self.image.draw(in: CGRect(x: 0.0,
                                   y: 0.0,
                                   width: self.imageAreaRect.width,
                                   height: self.imageAreaRect.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func scale(cornerPoint point: CGPoint, toImageViewPointInViewRect viewRect: CGRect) -> CGPoint {
        let pointY = 1.0 - point.y
        let scaleFactor = self.imageAreaRect.size
        
        return CGPoint(x: point.x * scaleFactor.width + self.imageAreaRect.origin.x,
                       y: pointY * scaleFactor.height + self.imageAreaRect.origin.y)
    }
    
    private func scaleLine(line: CGPoint) -> CGPoint {
        let pointY = 1.0 - line.y
        let scaleFactor = self.imageAreaRect.size
        
        return CGPoint(x: line.x * scaleFactor.width + self.imageAreaRect.origin.x,
                       y: pointY * scaleFactor.height + self.imageAreaRect.origin.y)
    }
}
