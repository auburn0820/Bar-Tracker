//
//  VideoSelectViewModel.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/06/28.
//

import Foundation
import UIKit
import Photos

class VideoSelectViewModel: ObservableObject {
    @Published var videoAssets = [AssetCell]()
    @Published var isTrackingViewPresented: Bool = false
    var assets: PHFetchResult<PHAsset>?
    var videoAsset: AVAsset?
    
    init() {
        loadAssetsFromLibrary()
    }
    
    func loadAssetsFromLibrary() {
        let assetsOptions = PHFetchOptions()
        
        assetsOptions.includeAssetSourceTypes = [.typeCloudShared, .typeUserLibrary, .typeiTunesSynced]
        assetsOptions.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        self.assets = PHAsset.fetchAssets(with: .video, options: assetsOptions)
    }
    
    func setAssetCellArray() {
        let imageManager = PHImageManager()
        let imageOptions = PHImageRequestOptions()
        
        imageOptions.isNetworkAccessAllowed = true
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.resizeMode = .fast
        
        guard let assets = self.assets else { return }
        
        assets.enumerateObjects({ (asset, _, _) in
            let identifier = asset.localIdentifier
            
            imageManager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: imageOptions) { (image, _) in
                if let image = image {
                    self.videoAssets.append(AssetCell(representedAssetIdentifer: identifier, image: image))
                }
            }
        })
    }
    
    func findPHAsset(identifier: String) -> PHAsset? {
        var foundAsset: PHAsset? = nil
        self.assets?.enumerateObjects { (asset, _, stop) in
            if asset.localIdentifier == identifier {
                foundAsset = asset
                stop.pointee = true
            }
        }
        
        return foundAsset
    }
    
    func setVideoAsset(identifier: String) {
        guard let asset = findPHAsset(identifier: identifier) else {
            fatalError("Failed to find asset with identifier \(identifier)")
        }
        
        let imageManger = PHImageManager.default()
        let videoOptions = PHVideoRequestOptions()
        videoOptions.deliveryMode = .highQualityFormat
        videoOptions.isNetworkAccessAllowed = true
        
        // escaping closure가 비동기로 동작하기 때문에 핸들링 해야 함
        imageManger.requestAVAsset(forVideo: asset, options: videoOptions) { (video, _, _) in
            DispatchQueue.main.async {
                if let video = video {
                    self.videoAsset = video
                    self.isTrackingViewPresented.toggle()
                }
            }
        }
    }
}

struct AssetCell {
    var representedAssetIdentifer: String = ""
    var image: UIImage
}
