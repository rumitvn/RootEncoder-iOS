//
//  RtspSwiftUIView.swift
//  app
//
//  Created by Pedro  on 20/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import SwiftUI
import RootEncoder

struct RtspSwiftUIView: View, ConnectChecker {
    
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
        if (rtspCamera.reTry(delay: 5000, reason: reason)) {
            toastText = "Retry"
            isShowingToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isShowingToast = false
            }
        } else {
            rtspCamera.stopStream()
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
    
    
    @State private var endpoint = "rtsp://192.168.1.3:8554/live/rum"
    @State private var bStreamText = "Start stream"
    @State private var bRecordText = "Start record"
    @State private var isShowingToast = false
    @State private var toastText = ""
    @State private var bitrateText = ""
    @State private var filePath: URL? = nil

    @State private var rtspCamera: RtspCamera!
    
    var body: some View {
        ZStack {
            let camera = CameraUIView()
            let cameraView = camera.view
            camera.edgesIgnoringSafeArea(.all)
            
            camera.onAppear {
                rtspCamera = RtspCamera(view: cameraView, connectChecker: self)
                rtspCamera.setRetries(reTries: 10)
                rtspCamera.startPreview()
            }
            camera.onDisappear {
                if (rtspCamera.isStreaming()) {
                    rtspCamera.stopStream()
                }
                if (rtspCamera.isOnPreview()) {
                    rtspCamera.stopPreview()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Menu("Filters") {
                        Button(action: {
                            rtspCamera.metalInterface?.clearFilters()
                        }) {
                            Text("No filter")
                        }
                        Button(action: {
                            rtspCamera.metalInterface?.setFilter(baseFilterRender: GreyScaleFilterRender())
                        }) {
                            Text("GreyScale")
                        }
                        Button(action: {
                            rtspCamera.metalInterface?.setFilter(baseFilterRender: SepiaFilterRender())
                        }) {
                            Text("Sepia")
                        }
                    }
                }.padding(.trailing, 16)
                TextField("rtsp://ip:port/app/streamname", text: $endpoint)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    .padding(.horizontal)
                    .keyboardType(.default)
                Text(bitrateText).foregroundColor(Color.blue)
                Spacer()
                HStack(alignment: .center, spacing: 16, content: {
                    Button(bRecordText) {
                        if (!rtspCamera.isRecording()) {
                            if (rtspCamera.prepareAudio() && rtspCamera.prepareVideo()) {
                                let url = getVideoUrl()
                                if (url != nil) {
                                    filePath = url
                                    rtspCamera.startRecord(path: url!)
                                    bRecordText = "Stop record"
                                }
                            }
                        } else {
                            rtspCamera.stopRecord()
                            if (filePath != nil) {
                                saveVideoToGallery(videoURL: filePath!)
                                filePath = nil
                            }
                            bRecordText = "Start record"
                        }
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                    Button(bStreamText) {
                        let endpoint = endpoint
                        if (!rtspCamera.isStreaming()) {
                            if (rtspCamera.prepareAudio() && rtspCamera.prepareVideo()) {
                                rtspCamera.startStream(endpoint: endpoint)
                                bStreamText = "Stop stream"
                            }
                        } else {
                            rtspCamera.stopStream()
                            bStreamText = "Start stream"
                            bitrateText = ""
                        }
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                    Button("Switch camera") {
                        rtspCamera.switchCamera()
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                }).padding(.bottom, 24)
            }.frame(alignment: .bottom)
        }.showToast(text: toastText, isShowing: $isShowingToast)
    }
}

#Preview {
    RtspSwiftUIView()
}
