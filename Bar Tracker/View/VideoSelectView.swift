//
//  VideoSelectView.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/06/28.
//

import SwiftUI
import AVFoundation

struct VideoSelectView: View {
    @StateObject var videoSelectViewModel = VideoSelectViewModel()
    @State var videoAsset: AVAsset?
    @State var trackingViewModal: Bool = false
    let imageFrame: CGFloat
    let layout: [GridItem]
    
    init() {
        self.imageFrame = UIScreen.main.bounds.size.width / 3
        self.layout = [ GridItem(.fixed(imageFrame)),
                        GridItem(.fixed(imageFrame)),
                        GridItem(.fixed(imageFrame))]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: layout) {
                    ForEach(videoSelectViewModel.videoAssets,
                            id: \.representedAssetIdentifer) { asset in
                        Button {
                            self.videoSelectViewModel.setVideoAsset(identifier: asset.representedAssetIdentifer)
                        } label: {
                            Image(uiImage: asset.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageFrame,
                                       height: imageFrame)
                                .clipped()
                        }
                        .fullScreenCover(isPresented: $videoSelectViewModel.isTrackingViewPresented) {
                            if let videoAsset = self.videoSelectViewModel.videoAsset {
                                TrackingView(videoAsset: videoAsset)
                            }
                        }
                    }
                }
            }
            .onAppear {
                self.videoSelectViewModel.setAssetCellArray()
            }
        }
    }
}

struct VideoSelectView_Previews: PreviewProvider {
    static var previews: some View {
        VideoSelectView()
    }
}
