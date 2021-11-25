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
    @State var video: AVAsset?
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
            ScrollView {
                LazyVGrid(columns: layout) {
                    ForEach(videoSelectViewModel.videoAssets,
                            id: \.id) { asset in
                        Button {
                            self.videoSelectViewModel.setVideoAsset(identifier: asset.id)
                        } label: {
                            Image(uiImage: asset.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageFrame,
                                       height: imageFrame)
                                .clipped()
                        }
                        .fullScreenCover(isPresented: $videoSelectViewModel.isTrackingViewPresented) {
                            if let video = self.videoSelectViewModel.videoAsset {
                                TrackingView(video: video)
                            }
                        }
                    }
                }
            }
            .onAppear {
                self.videoSelectViewModel.requestAcessToPhotoLibrary()
            }
    }
}

struct VideoSelectView_Previews: PreviewProvider {
    static var previews: some View {
        VideoSelectView()
    }
}
