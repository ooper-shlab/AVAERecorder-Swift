//
//  ViewController.swift
//  AVAERecorder
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/4/21.
//  See LICENSE.txt .
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet weak var recStartButton: UIButton!
    @IBOutlet weak var recStopButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    var audioFile: AVAudioFile?
    
    var engine: AVAudioEngine!
    let connectionFormat = AVAudioFormat(commonFormat: .PCMFormatFloat32, sampleRate: 44_100, channels: 2, interleaved: false)
    
    var playerEngine: AVAudioEngine!
    var playerNode: AVAudioPlayerNode!
    
    var shouldStopRecording: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        engine = AVAudioEngine()
        let input = engine.inputNode
        
        input.installTapOnBus(0, bufferSize: 4096, format: connectionFormat, block: {
            buffer, when in
            println("\(buffer.frameLength) \(buffer.frameCapacity) \(AVAudioTime.secondsForHostTime(when.hostTime))");
            var blockError: NSError?
            let written = self.audioFile?.writeFromBuffer(buffer, error: &blockError)
            if blockError != nil {
                println(blockError!)
            } else {
                println("*\(written)")
            }
            if self.shouldStopRecording {
                dispatch_async(dispatch_get_main_queue()) {
                    self.stopRecording()
                }
            }
        })
        
        playerEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        playerEngine.attachNode(playerNode)
        playerEngine.connect(playerNode, to: playerEngine.outputNode, format: connectionFormat)
        var error: NSError?
        let started = playerEngine.startAndReturnError(&error)
        if error != nil {
            println(error!)
        }
        
        playerNode.play()
    }
    
    override func viewWillAppear(animated: Bool) {
        recStopButton.enabled = false
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    @IBAction func recStart(sender: AnyObject) {
        recStartButton.enabled = false
        recStopButton.enabled = true
        playButton.enabled = false
        
        var error: NSError?
        
        // recorded file path
        let filePaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentDir = filePaths.last! as! String
        let path = documentDir.stringByAppendingPathComponent("recorded.caf")
        let recordingURL = NSURL(fileURLWithPath: path)
        
        audioFile = AVAudioFile(forWriting: recordingURL, settings: connectionFormat.settings,
            error: &error)
        if error != nil {
            println(error!)
        }
        
        // start engine
        let started = engine.startAndReturnError(&error)
        
        if error != nil {
            println(error!)
        }
    }
    
    func stopRecording() {
        recStartButton.enabled = true
        recStopButton.enabled = false
        playButton.enabled = true
        
        engine.stop()
        audioFile = nil
        
        shouldStopRecording = false
    }
    
    @IBAction func recStop(sender: AnyObject) {
        engine.inputNode.volume = 0.0
        shouldStopRecording = true
    }
    
    @IBAction func play(sender: AnyObject) {
        recStartButton.enabled = false
        recStopButton.enabled = false
        playButton.enabled = false
        // recorded file path
        let filePaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentDir = filePaths.last! as! String
        let path = documentDir.stringByAppendingPathComponent("recorded.caf")
        let recordingURL = NSURL(fileURLWithPath: path)
        
        var error: NSError?
        let playedFile = AVAudioFile(forReading: recordingURL, error: &error)
        playerNode.scheduleFile(playedFile, atTime: nil) {
            [weak self] () in
            dispatch_async(dispatch_get_main_queue()) {
                //stopping player or engine herein causes remaining buffer unplayed.
                self!.audioPlayerDidCompleteScheduledFile()
            }
        }
        
    }
    
    func audioPlayerDidCompleteScheduledFile() {
        recStartButton.enabled = true
        recStopButton.enabled = false
        playButton.enabled = true
    }
}