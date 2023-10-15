//
// Created by Pedro  on 17/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import encoder
import rtmp

public class RtmpCamera: CameraBase {

    private var client: RtmpClient!

    public init(view: UIView, connectChecker: ConnectCheckerRtmp) {
        client = RtmpClient(connectCheckerRtmp: connectChecker)
        super.init(view: view)
    }

    public func setAuth(user: String, password: String) {
        //client.setAuth(user: user, password: password)
    }

    public func setCodec(codec: CodecUtil) {
        videoEncoder.setCodec(codec: codec)
    }

    public func reTry(delay: Int, reason: String, backUrl: String? = nil) -> Bool {
        let result = client.shouldRetry(reason: reason)
        if (result) {
            videoEncoder.forceKeyFrame()
            client.reconnect(delay: delay, backupUrl: backUrl)
        }
        return result
    }
    
    public func setRetries(reTries: Int) {
        client.setRetries(reTries: reTries)
    }
    
    public override func prepareAudioRtp(sampleRate: Int, isStereo: Bool) {
        super.prepareAudioRtp(sampleRate: sampleRate, isStereo: isStereo)
        client.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }

    public override func stopStreamRtp() {
        client.disconnect()
    }
    
    public override func startStreamRtp(endpoint: String) {
        client.connect(url: endpoint)
    }
    
    public override func getAacDataRtp(frame: Frame) {
        client.sendAudio(buffer: frame.buffer!, ts: frame.timeStamp!)
    }

    public override func getH264DataRtp(frame: Frame) {
        client.sendVideo(buffer: frame.buffer!, ts: frame.timeStamp!)
    }

    public override func onSpsPpsVpsRtp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        client.setVideoInfo(sps: sps, pps: pps, vps: vps)
    }
}
