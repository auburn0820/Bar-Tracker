//
//  VideoSelectView.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/06/28.
//

import SwiftUI

struct VideoSelectView: View {
    @StateObject var videoSelectViewModel = VideoSelectViewModel()
    
    
    var body: some View {
        GeometryReader { geometry in
            let imageFrame = geometry.size.width / 3
            let layout = [ GridItem(.fixed(imageFrame)),
                           GridItem(.fixed(imageFrame)),
                           GridItem(.fixed(imageFrame))]
            ScrollView {
                LazyVGrid(columns: layout) {
                    ForEach(videoSelectViewModel.videoAssets,
                            id: \.representedAssetIdentifer) { asset in
                        NavigationLink(
                            destination: TrackingView()) {
                            Image(uiImage: asset.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageFrame,
                                       height: imageFrame)
                                .clipped()
                        }
                    }
                }
            }
            .onAppear {
                self.videoSelectViewModel.setVideoAsset()
            }
        }
    }
}

struct VideoSelectView_Previews: PreviewProvider {
    static var previews: some View {
        VideoSelectView()
    }
}
