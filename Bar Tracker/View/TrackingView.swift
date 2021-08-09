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
    @State var isStatusBarPresented: Bool = true
    var video: AVAsset

    init(video: AVAsset) {
        self.video = video
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if self.isStatusBarPresented {
                    HStack {
                        Button(action: {
                            self.trackingViewModel.isFinished.toggle()
                            self.presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Text("Back")
                        })
                        .padding(.leading, 20)
                        .padding(.top, 50)
                        Spacer()
                        Button(action: {
                            self.trackingViewModel.performTracking()
                        }, label: {
                            Text("Play")
                        })
                        .padding(.trailing, 20)
                        .padding(.top, 50)
                    }
                    .frame(width: geometry.size.width, height: 100, alignment: .center)
                    .background(Color.black.opacity(0.8).blur(radius: 0.5))
                    .position(x: geometry.size.width / 2)
                    .zIndex(1)
                }
                Group {
                    TrackingImageView(trackingViewModel: self.trackingViewModel, video: self.video)
                        .gesture(TapGesture(count: 1)
                                    .onEnded {
                                        self.isStatusBarPresented.toggle()
                                    })
                        .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        self.trackingViewModel.handleDragging(value: value, isDragStart: &self.isDragStart, state: .onChanged)
                                    }
                                    .onEnded { value in
                                        self.trackingViewModel.handleDragging(value: value, isDragStart: &self.isDragStart, state: .onEnded)
                                    }
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                .contentShape(Rectangle())
                .gesture(TapGesture(count: 1)
                            .onEnded {
                                self.isStatusBarPresented.toggle()
                            })
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onAppear {
                self.trackingViewModel.isFinished = false
                self.trackingViewModel.setVideoAsset(video: self.video)
                self.trackingViewModel.setFrameSubscriber()
                self.trackingViewModel.displayFirstVideoFrame()
            }
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
