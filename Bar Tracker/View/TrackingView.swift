//
//  TrackingView.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/06/28.
//

import SwiftUI
import AVFoundation
import AVKit

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
            }
            Spacer()
            TrackingImageView(trackingViewModel: self.trackingViewModel, video: self.video)
            Spacer()
        }
        .onAppear {
            self.trackingViewModel.videoAsset = video
            self.trackingViewModel.displayFirstVideoFrame()
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
