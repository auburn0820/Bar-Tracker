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
    
    func loadAssetsFromLibrary() -> PHFetchResult<PHAsset>? {
        let assetsOptions = PHFetchOptions()
        
        assetsOptions.includeAssetSourceTypes = [.typeCloudShared, .typeUserLibrary, .typeiTunesSynced]
        assetsOptions.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        return PHAsset.fetchAssets(with: .video, options: assetsOptions)
    }
    
    func setVideoAsset() {
        guard let assets = loadAssetsFromLibrary() else {
            print("Failed to find asset")
            return
        }
        
        convertPHAssetToAssetCell(assets: assets)
    }
    
    func convertPHAssetToAssetCell(assets: PHFetchResult<PHAsset>) {
        let imageManager = PHImageManager()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        
        assets.enumerateObjects({ (asset, _, _) in
            let identifier = asset.localIdentifier
            imageManager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: options) { (image, _) in
                if let image = image {
                    let assetCell = AssetCell(image: image, representedAssetIdentifer: identifier)
                    self.videoAssets.append(assetCell)
                }
            }
        })
    }
}

struct AssetCell {
    var image: UIImage
    var representedAssetIdentifer: String = ""
}
