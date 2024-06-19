//
//  RtspRestreamSwiftUIView.swift
//  app
//
//  Created by Rum Nguyen on 19/6/24.
//  Copyright © 2024 pedroSG94. All rights reserved.
//

import Foundation

import SwiftUI
import RootEncoder
import AVKit

struct RtspRestreamSwiftUIView: View, ConnectChecker {
    
    func onConnectionSuccess() {
        print("connection success")
        toastText = "connection success"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    func onConnectionFailed(reason: String) {
        print("connection failed: \(reason)")
        if (rtspStream.reTry(delay: 5000, reason: reason)) {
            toastText = "Retry"
            isShowingToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isShowingToast = false
            }
        } else {
            rtspStream.stopStream()
            bStreamText = "Start stream"
            bitrateText = ""
            toastText = "connection failed: \(reason)"
            isShowingToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isShowingToast = false
            }
        }
    }
    
    func onNewBitrate(bitrate: UInt64) {
        print("new bitrate: \(bitrate)")
        bitrateText = "bitrate: \(bitrate) bps"
    }
    
    func onDisconnect() {
        print("disconnected")
        toastText = "disconnected"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    func onAuthError() {
        print("auth error")
        toastText = "auth error"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    func onAuthSuccess() {
        print("auth success")
        toastText = "auth success"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    @State private var sourceEndpoint = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
//    @State private var sourceEndpoint = "rtsp://192.168.1.3:8554/source/bida"
    @State private var destinationEndpoint = "rtsp://192.168.1.3:8554/live/rum"
    @State private var bStreamText = "Start stream"
    @State private var isShowingToast = false
    @State private var toastText = ""
    @State private var bitrateText = ""
    @State private var filePath: URL? = nil

    @State private var rtspStream: RtspStream!
    
    var body: some View {
        ZStack {
            let camera = CameraUIView()
            let cameraView = camera.view
            camera.edgesIgnoringSafeArea(.all)
            
            camera.onAppear {
                rtspStream = RtspStream(connectChecker: self)
                rtspStream.setRetries(reTries: 10)
            }
            camera.onDisappear {
                if (rtspStream.isStreaming()) {
                    rtspStream.stopStream()
                }
            }
            
            if (rtspStream != nil && rtspStream.isStreaming()) {
                
            }
            
            VStack {
                TextField("rtsp://ip:port/app/streamname", text: $sourceEndpoint)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    .padding(.horizontal)
                    .keyboardType(.default)
                TextField("rtsp://ip:port/app/streamname", text: $destinationEndpoint)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    .padding(.horizontal)
                    .keyboardType(.default)
                Text(bitrateText).foregroundColor(Color.blue)
                Spacer()
                HStack(alignment: .center, spacing: 16, content: {
                    Button(bStreamText) {
                        let endpoint = destinationEndpoint
                        if (!rtspStream.isStreaming()) {
                            if (rtspStream.prepareAudio() && rtspStream.prepareVideo()) {
                                rtspStream.startStream(endpoint: endpoint)
                                bStreamText = "Stop stream"
                            }
                        } else {
                            rtspStream.stopStream()
                            bStreamText = "Start stream"
                            bitrateText = ""
                        }
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                }).padding(.bottom, 24)
            }.frame(alignment: .bottom)
        }.showToast(text: toastText, isShowing: $isShowingToast)
    }
}

#Preview {
    RtspRestreamSwiftUIView()
}

