//
//  TrackingView.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/06/28.
//

import SwiftUI
import AVFoundation

struct TrackingView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var trackingViewModel = TrackingViewModel()
    var video: AVAsset
    
    init(video: AVAsset) {
        self.video = video
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Back")
                }
                .padding()
                Spacer()
                Button {
                    self.trackingViewModel.drawLines()
                } label: {
                    Text("Draw Lines")
                }
                .padding()
            }
            Spacer()
            TrackingImageView(trackingViewModel: self.trackingViewModel, video: self.video)
//            TrackingImageViewRepresentable(videoFrame: self.$trackingViewModel.videoFrame)
            Spacer()
        }
        .onAppear {
            self.trackingViewModel.setVideoAsset(video: self.video)
            self.trackingViewModel.displayFirstVideoFrame()
            self.trackingViewModel.setVideoTrack()
        }
    }
}

struct TrackingImageView: View {
    @ObservedObject var trackingViewModel: TrackingViewModel

    init(trackingViewModel: TrackingViewModel, video: AVAsset) {
        self.trackingViewModel = trackingViewModel
    }

    var body: some View {
        if let frame = self.trackingViewModel.videoFrame {
            Image(uiImage: frame)
                
        }
    }
}

#if DEBUG
struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingView(video: AVAsset())
    }
}
#endif
