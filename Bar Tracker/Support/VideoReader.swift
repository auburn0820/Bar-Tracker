//
//  VideoReader.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/06/28.
//

import Foundation
import AVFoundation
import Darwin

class VideoReader {
    static private let millisecondsInSecond: Float32 = 1000.0
    
    var frameRateInMilliseconds: Float32 {
        return self.videoTrack.nominalFrameRate
    }
    
    var frameRateInSeconds: Float32 {
        return self.frameRateInMilliseconds * VideoReader.millisecondsInSecond
    }
    
    var affineTransform: CGAffineTransform {
        return self.videoTrack.preferredTransform.inverted()
    }
    
    var orientation: CGImagePropertyOrientation {
        let angleInDegrees = atan2(self.affineTransform.b, self.affineTransform.a) * CGFloat(180) / CGFloat.pi
        
        var orientation: UInt32 = 1
        switch angleInDegrees {
        case 0:
            orientation = 1
        case 180:
            orientation = 3
        case -180:
            orientation = 3
        case 90:
            orientation = 8
        case -90:
            orientation = 6
        default:
            orientation = 1
        }
        
        return CGImagePropertyOrientation(rawValue: orientation)!
    }
    
    private var videoAsset: AVAsset!
    private var videoTrack: AVAssetTrack!
    private var assetReader: AVAssetReader!
    private var videoAssetReaderOutput: AVAssetReaderOutput!
    
    init?(videoAsset: AVAsset) {
        self.videoAsset = videoAsset
        let array = self.videoAsset.tracks(withMediaType: AVMediaType.video)
        self.videoTrack = array[0]
        
        
    }
    
    func restartReading() -> Bool {
        do {
            self.assetReader = try AVAssetReader(asset: videoAsset)
        } catch {
            print("Failed to create AVAssetReader object: \(error)")
            return false
        }
        
        self.videoAssetReaderOutput = AVAssetReaderTrackOutput(track: self.videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8PlanarFullRange])
        guard self.videoAssetReaderOutput != nil else {
            return false
        }
        
        self.videoAssetReaderOutput.alwaysCopiesSampleData = true
        
        guard self.assetReader.canAdd(videoAssetReaderOutput) else {
            return false
        }
        
        self.assetReader.add(videoAssetReaderOutput)
        
        return self.assetReader.startReading()
    }
    
    func nextFrame() -> CVPixelBuffer? {
        guard let sampleBuffer = self.videoAssetReaderOutput.copyNextSampleBuffer() else {
            return nil
        }
        
        return CMSampleBufferGetImageBuffer(sampleBuffer)
    }
}
