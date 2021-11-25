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
    // MARK: Properties
    @Published var videoAssets = [AssetCell]()
    @Published var isTrackingViewPresented: Bool = false
    var assets: PHFetchResult<PHAsset>?
    var videoAsset: AVAsset?
    
    // MARK: Methods
    func requestAcessToPhotoLibrary() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            switch status {
            case .authorized:
                self.loadAssetsFromLibrary()
                self.setAssetCellArray()
            default:
                break
            }
        }
    }
    
    func loadAssetsFromLibrary() {
        let assetsOptions = PHFetchOptions()
        assetsOptions.includeAssetSourceTypes = [.typeCloudShared, .typeUserLibrary, .typeiTunesSynced]
        assetsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        self.assets = PHAsset.fetchAssets(with: .video, options: assetsOptions)
    }
    
    func setAssetCellArray() {
        let imageManager = PHImageManager()
        let imageOptions = PHImageRequestOptions()
        
        imageOptions.isNetworkAccessAllowed = true
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.resizeMode = .fast
        
        guard let assets = self.assets else {
            return
        }
        
        assets.enumerateObjects({ (asset, _, _) in
            let identifier = asset.localIdentifier
            
            imageManager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: imageOptions) { [weak self] (image, _) in
                if let image = image {
                    self?.videoAssets.append(AssetCell(id: identifier, image: image))
                }
            }
        })
    }
    
    func findPHAssetWithIdentifier(identifier: String) -> PHAsset? {
        var foundAsset: PHAsset?
        guard let assets = self.assets else {
            return nil
        }
        
        assets.enumerateObjects { (asset, _, stop) in
            if asset.localIdentifier == identifier {
                foundAsset = asset
                stop.pointee = true
            }
        }
        
        return foundAsset
    }
    
    func setVideoAsset(identifier: String) {
        guard let asset = findPHAssetWithIdentifier(identifier: identifier) else {
            fatalError("Failed to find asset with identifier \(identifier)")
        }
        
        let imageManger = PHImageManager.default()
        let videoOptions = PHVideoRequestOptions()
        videoOptions.deliveryMode = .highQualityFormat
        videoOptions.isNetworkAccessAllowed = true
        
        imageManger.requestAVAsset(forVideo: asset, options: videoOptions) { [weak self] (video, _, _) in
            DispatchQueue.main.async {
                if let video = video {
                    self?.videoAsset = video
                    self?.isTrackingViewPresented.toggle()
                }
            }
        }
    }
}

struct AssetCell: Identifiable {
    let id: String
    let image: UIImage
}
