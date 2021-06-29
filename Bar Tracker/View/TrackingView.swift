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
    var videoAsset: AVAsset
    
    init(videoAsset: AVAsset) {
        self.videoAsset = videoAsset
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
            VideoPlayer(player: AVPlayer(playerItem: AVPlayerItem(asset: self.videoAsset)))
        }
    }
}

struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingView(videoAsset: AVAsset())
    }
}
