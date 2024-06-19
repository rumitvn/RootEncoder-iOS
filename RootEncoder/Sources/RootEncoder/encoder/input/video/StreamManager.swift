//
//  StreamManager.swift
//
//
//  Created by Rum Nguyen on 20/6/24.
//

import Foundation
import AVFoundation
import CoreVideo

public class StreamManager: NSObject {
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?
    private var running = false
    private let callbackVideo: GetCameraData?
    private var videoTrack: AVAssetTrack?

    public init(streamURL: URL, callbackVideo: GetCameraData?) {
        self.callbackVideo = callbackVideo
        super.init()
        self.setupPlayer(with: streamURL)
    }

    private func setupPlayer(with url: URL) {
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
        playerItem?.add(videoOutput!)

        // Observe the status property of the player item
        playerItem?.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
    }

    deinit {
        playerItem?.removeObserver(self, forKeyPath: "status")
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if playerItem?.status == .readyToPlay {
                // Now the asset's tracks should be loaded
                if let callback = callbackVideo {
                    print("Width: \(getWidth()), Height: \(getHeight())")
                }
                // Start the display link now that the player is ready
                
            } else if playerItem?.status == .failed {
                print("Player item failed to load")
            }
        }
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(readNextBuffer))
        displayLink?.add(to: .main, forMode: .default)
    }

    public func start() {
        if running {
            return
        }
        running = true

        startDisplayLink()
        player?.play()
    }

    public func stop() {
        running = false
        player?.pause()
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func readNextBuffer() {
        guard running, let videoOutput = videoOutput else { return }

        let currentTime = CACurrentMediaTime()

        if videoOutput.hasNewPixelBuffer(forItemTime: CMTime(seconds: currentTime, preferredTimescale: 600)),
           let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: CMTime(seconds: currentTime, preferredTimescale: 600), itemTimeForDisplay: nil) {

            var sampleBuffer: CMSampleBuffer?
            var formatDescription: CMFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
            var timingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: CMTime(seconds: currentTime, preferredTimescale: 600), decodeTimeStamp: .invalid)
            CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDescription!, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)

            if let sampleBuffer = sampleBuffer {
                self.callbackVideo?.getYUVData(from: sampleBuffer)
            }
        }
    }

    @objc private func itemDidPlayToEndTime(_ notification: Notification) {
        print("Stream ended.")
        stop()
    }

    public func getWidth() -> Int {
//        return 1920
        guard let track = playerItem?.asset.tracks(withMediaType: .video).first else {
            return 0
        }
        let dimensions = CMVideoFormatDescriptionGetDimensions(track.formatDescriptions.first as! CMFormatDescription)
        return Int(dimensions.width)
    }

    public func getHeight() -> Int {
//        return 1080
        guard let track = playerItem?.asset.tracks(withMediaType: .video).first else {
            return 0
        }
        let dimensions = CMVideoFormatDescriptionGetDimensions(track.formatDescriptions.first as! CMFormatDescription)
        return Int(dimensions.height)
    }
}
