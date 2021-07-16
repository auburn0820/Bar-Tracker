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
    @State var isDragStart: Bool = true
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
                    self.trackingViewModel.performTracking()
                } label: {
                    Text("Play")
                }
                .padding()
            }
            Spacer()
            TrackingImageView(trackingViewModel: self.trackingViewModel, video: self.video)
                .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if self.isDragStart {
                                    self.trackingViewModel.rubberbandingStart = value.startLocation
                                } else {
                                    self.trackingViewModel.rubberbandingStart.applying(CGAffineTransform(translationX: value.translation.width, y: value.translation.height))
                                }
                                
                                self.trackingViewModel.rubberbandingVector = CGPoint(x: value.translation.width, y: value.translation.height)
                                self.trackingViewModel.drawLinesAndRectangle(isTouchesEnded: false)
                            }
                            .onEnded { value in
                                self.trackingViewModel.drawLinesAndRectangle(isTouchesEnded: true)
                                self.trackingViewModel.setObjectToTrack()
                            }
                )
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
