//
//  ViewController.swift
//  AVAERecorder
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/4/21.
//  See LICENSE.txt .
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate {
    
    @IBOutlet weak var recStartButton: UIButton!
    @IBOutlet weak var recStopButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    var audioFile: AVAudioFile?
    
    var engine: AVAudioEngine!
    let connectionFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44_100, channels: 2, interleaved: false)!
    
    var playerEngine: AVAudioEngine!
    var playerNode: AVAudioPlayerNode!
    
    var shouldStopRecording: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        engine = AVAudioEngine()
        let input = engine.inputNode
        
        input.installTap(onBus: 0, bufferSize: 4096, format: connectionFormat) {
            buffer, when in
//            print("\(buffer.frameLength) \(buffer.frameCapacity) \(AVAudioTime.seconds(forHostTime: when.hostTime))");
            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                print(error)
            }
            if self.shouldStopRecording {
                DispatchQueue.main.async {
                    self.stopRecording()
                }
            }
        }
        
        playerEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        playerEngine.attach(playerNode)
        playerEngine.connect(playerNode, to: playerEngine.outputNode, format: connectionFormat)
        do {
            try playerEngine.start()
        } catch {
            print(error)
        }
        
        playerNode.play()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        recStopButton.isEnabled = false
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    @IBAction func recStart(_ sender: AnyObject) {
        recStartButton.isEnabled = false
        recStopButton.isEnabled = true
        playButton.isEnabled = false
        
        // recorded file path
        let fileURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirURL = fileURLs.last!
        let recordingURL = documentDirURL.appendingPathComponent("recorded.caf")
        
        do {
            audioFile = try AVAudioFile(forWriting: recordingURL, settings: connectionFormat.settings)
        } catch {
            print(error)
            audioFile = nil
        }
        
        // start engine
        do {
            try engine.start()
        } catch {
            print(error)
        }
        
    }
    
    func stopRecording() {
        recStartButton.isEnabled = true
        recStopButton.isEnabled = false
        playButton.isEnabled = true
        
        engine.stop()
        audioFile = nil
        
        shouldStopRecording = false
    }
    
    @IBAction func recStop(_ sender: AnyObject) {
        engine.inputNode.volume = 0.0
        shouldStopRecording = true
    }
    
    @IBAction func play(_ sender: AnyObject) {
        recStartButton.isEnabled = false
        recStopButton.isEnabled = false
        playButton.isEnabled = false
        // recorded file path
        let fileURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirURL = fileURLs.last!
        let recordingURL = documentDirURL.appendingPathComponent("recorded.caf")
        
        do {
            let playedFile = try AVAudioFile(forReading: recordingURL)
            playerNode.scheduleFile(playedFile, at: nil) {
                [weak self] () in
                DispatchQueue.main.async {
                    //stopping player or engine herein causes remaining buffer unplayed.
                    self!.audioPlayerDidCompleteScheduledFile()
                }
            }
        } catch {
            print(error)
        }
        
    }
    
    func audioPlayerDidCompleteScheduledFile() {
        recStartButton.isEnabled = true
        recStopButton.isEnabled = false
        playButton.isEnabled = true
    }
}
