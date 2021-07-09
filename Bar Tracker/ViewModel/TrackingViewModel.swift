//
//  TrackingViewModel.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/06/29.
//

import Foundation
import AVFoundation
import SwiftUI

class TrackingViewModel: ObservableObject {
    @Published var videoFrame: UIImage?
    
    var videoAsset: AVAsset?
    
    func displayFirstVideoFrame() {
        guard let videoAsset = self.videoAsset else { return }
        let videoImageGenerator = AVAssetImageGenerator(asset: videoAsset)
        videoImageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
        
        do {
            let cgImage = try videoImageGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            if let thumbnail = resizeUIImage(imageToResize: uiImage,
                                             width: UIScreen.main.bounds.width) {
                self.videoFrame = thumbnail
            }
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func resizeUIImage(imageToResize image: UIImage, width: CGFloat) -> UIImage? {
        let size = image.size
        
        let widthRatio = width / size.width
        let height = size.height * widthRatio
        
        let newSize = CGSize(width: width, height: height)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
