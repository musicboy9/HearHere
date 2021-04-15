//
//  AudioSamplePlayer.swift
//  OpenALSample
//
//  Created by 김승수 on 2016. 4. 30..
//  Copyright © 2016년 Korea Science Academy. All rights reserved.
//

import UIKit
import AVFoundation
import OpenAL
import AudioToolbox

typealias ALCcontext = OpaquePointer
typealias ALCdevice = OpaquePointer

let kDefaultDistance: Float = 25.0

class AudioSamplePlayer: NSObject {
    
    var source: ALuint = 0
    var defaultBuffer: ALuint = 0
    var alarmBuffer: ALuint = 0
    var buffers: [ALuint]
    var context: ALCcontext? = nil
    var device: ALCdevice? = nil
    var error: ALenum = AL_NO_ERROR
    
    var data1: UnsafeMutableRawPointer? = nil
    var data2: UnsafeMutableRawPointer? = nil

    dynamic var isPlaying: Bool = false
    
    override init() {
        buffers = [defaultBuffer, alarmBuffer]
        
        super.init()
        
        // Start with our sound source slightly in front of the listener
        self._sourcePos = CGPoint(x: 0.0, y: -70.0)
        // Put the listener in the center of the stage
        self._listenerPos = CGPoint(x: 0.0, y: 0.0)
        // Listener looking straight ahead
        self._listenerRotation = 0.0
        
        self.initOpenAL()
    }
    
    func initOpenAL() {
        device = alcOpenDevice(nil)
        if device != nil {
            context = alcCreateContext(device, nil)
            if context != nil {
                alcMakeContextCurrent(context)
                
                alGetError()
                alGenBuffers(2, &buffers)
                self.checkError(code: "Error Generating Buffers")
                
                alGenSources(1, &source)
                self.checkError(code: "Error Generating Sources")
            }
        }
        alGetError()
        
        self.initBuffer()
        self.initSource()
    }
    
    private func initBuffer() {
        var format1: ALenum = 0
        var format2: ALenum = 0
        var size1: ALsizei = 0
        var size2: ALsizei = 0
        var freq1: ALsizei = 0
        var freq2: ALsizei = 0
        
        let bundle1 = Bundle.main
        let bundle2 = Bundle.main
        
        
        let path1 = bundle1.path(forResource: "navigationTone", ofType: "caf")
        if path1 != nil {
            let fileURL1 = NSURL(fileURLWithPath: path1!)      
            
            data1 = MyGetOpenALAudioData(inFileURL: fileURL1, &size1, &freq1, &format1)
            
            self.checkError(code: "Error Loading Default Sound")
            
            alBufferData(buffers[0], format1, data1, size1, freq1)
            MyFreeOpenALAudioData(data: data1!, size1)
            
            self.checkError(code: "Error Attaching Default Sound to Buffer")
        }
        
        let path2 = bundle2.path(forResource: "checkpointArrival", ofType: "caf")
        if path2 != nil {
            let fileURL2 = NSURL(fileURLWithPath: path2!)
            
            data2 = MyGetOpenALAudioData(inFileURL: fileURL2, &size2, &format2, &freq2)
            
            self.checkError(code: "Error Loading Alarm Sound")
            
            alBufferData(buffers[1], format2, data2, size2, freq2)
            MyFreeOpenALAudioData(data: data2!, size2)
            
            self.checkError(code: "Error Attaching Alarm Sound to Buffer")
        }
    }
    
    private func initSource() {
        alGetError()    // clear error.
        
        alSourcei(source, AL_LOOPING, AL_TRUE)  // sets an integer property of the source.
        
        // Set Source Position
        let sourcePosAL: [Float] = [Float(sourcePos.x), kDefaultDistance, Float(sourcePos.y)]
        alSourcefv(source, AL_POSITION, sourcePosAL)
        
        // Set Source Reference Distance
        alSourcef(source, AL_REFERENCE_DISTANCE, 50.0)
        
        // attach OpenAL Buffer to OpenAL Source
        alSourcei(source, AL_BUFFER, ALint(buffers[0]))
        
        self.checkError(code: "Error Attaching the Buffer to the Source")
        
    }
    
    func checkError(code: String) {
        error = alGetError()
        if error != AL_NO_ERROR {
            print("\(code): \(error)")
        }
    }
    
    //MARK: Play / Pause
    
    func startDefaultSound() {
        print("Start!")
        // begin playing the source file
        alSourcei(source, AL_BUFFER, ALint(buffers[0]))
        alSourcei(source, AL_LOOPING, AL_TRUE)
        alSourcePlay(source)
        checkError(code: "1Error from Starting the Default Sound")
        if self.error == AL_NO_ERROR {
            self.isPlaying = true
        }
    }
    
    func startArrivalSound() {
        print("Start Alarm!")
        alSourcei(source, AL_LOOPING, AL_FALSE)
        alSourcei(source, AL_BUFFER, ALint(buffers[1]))
        alSourcePlay(source)
        checkError(code: "2Error from Starting the Alarm Sound")
        if self.error == AL_NO_ERROR {
            self.isPlaying = true
        }
        checkError(code: "3Error from Detaching the Alarm Sound")
        if self.error == AL_NO_ERROR {
            self.isPlaying = false
        }
    }
    
    func stopSound() {
        print("Stop!")
        // stop playing the source file
        alSourceStop(source)
        checkError(code: "4Error from Stoping the Sound")
        if self.error == AL_NO_ERROR {
            self.isPlaying = false
        }
        
        alSourcei(source, AL_BUFFER, ALint(0))
    }

    
    //MARK: Setters / Getters
    
    // coordinate of the source.
    private var _sourcePos: CGPoint = CGPoint()
    dynamic var sourcePos: CGPoint {
        get { return self._sourcePos }
        set(SOURCEPOS) {
            self._sourcePos = SOURCEPOS
            // set a float point-vecor property of a source.
            let sourcePosAL: [Float] = [Float(self._sourcePos.x), kDefaultDistance, Float(self._sourcePos.y)]
            // move the coordinate of the source.
            alSourcefv(source, AL_POSITION, sourcePosAL)
        }
    }
    
    // coordinate of the listener.
    private var _listenerPos: CGPoint = CGPoint()
    dynamic var listenerPos: CGPoint {
        get { return self._listenerPos }
        set(LISTENERPOS) {
            self._listenerPos = LISTENERPOS
            // set a float point-vecor property of a listener.
            let listenterPosAL: [Float] = [Float(self._listenerPos.x), 0.0, Float(self._listenerPos.y)]
            // move the coordinate of the listener.
            alListenerfv(AL_POSITION, listenterPosAL)
        }
    }
    
    private var _listenerRotation: CGFloat = 0
    dynamic var listenerRotation: CGFloat {
        get { return self._listenerRotation }
        set(radians) {
            self._listenerRotation = radians
            let orientation: [Float] = [Float(cos(radians + CGFloat(M_PI_2))), Float(sin(radians + CGFloat(M_PI_2))), 0.0, 0.0, 0.0, 1.0]
            // Set our listener orientation (rotation)
            alListenerfv(AL_ORIENTATION, orientation)
        }
    }

}
