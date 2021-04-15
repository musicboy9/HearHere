//
//  bluetoothConnectionViewController.swift
//  HearHereVer2
//
//  Created by 고영민 on 2016. 8. 3..
//  Copyright © 2016년 고영민. All rights reserved.
//

import UIKit
import AVFoundation
import MapKit

enum ConnectionState: Int{
    case NoDevice = 0
    case ConnectionFail = 1
    case DeviceConnected = 2
}

class BluetoothConnectionViewController: UIViewController {
    
//MARK: variables
    
    var bluetoothSearcher = BluetoothPeripheralSearcher()
    
    var connectionState = ConnectionState.NoDevice
    
    var audioPlayer = AVAudioPlayer()
    
    var route = MKRoute()
    
//MARK: functions
    
    func buttonSettingWhenLoading() {
        self.loadingButton.isEnabled = false
        if Locale.current.languageCode! == "ko"{
            self.loadingButton.setTitle("기기를 연결중입니다. 잠시만 기다려주십시오", for: UIControlState.normal)
        } else {
            self.loadingButton.setTitle("Connecting Device. Please wait for a moment", for: UIControlState.normal)
        }
    }

//MARK: IBOutlet
    
    @IBOutlet weak var loadingButton: UIButton! {
        didSet {
            self.loadingButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
            buttonSettingWhenLoading()
        }
    }

//MARK: IBAction
    
    @IBAction func buttonTouched(_ sender: AnyObject) {
        switch self.connectionState {
        case .NoDevice:
            self.bluetoothSearcher.scanForPeripherials()
            self.buttonSettingWhenLoading()
        case .ConnectionFail:
            self.bluetoothSearcher.scanForPeripherials()
            self.buttonSettingWhenLoading()
        case .DeviceConnected:
            performSegue(withIdentifier: "bluetoothConnected", sender: self)
        }
    }
    
//MARK: AVFoundation
    
    func soundPlay(fileName: String, fileType: String) {
        let alertSound = Bundle.main.path(forResource: fileName, ofType: fileType) // alertSound을 bundle에 추가함
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: alertSound!)) // audioPlayer에 alertSound를 추가함
        } catch {
            print("error occured")
        }
        self.audioPlayer.prepareToPlay() // buffer를 미리 추가하는 과정
        self.audioPlayer.play()
    }
    
    
//MARK: UIViewController
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.noDevice), name: NSNotification.Name(rawValue: "noDevice"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceConnectionFailure), name: NSNotification.Name(rawValue: "deviceConnectionFailure"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceConnected), name: NSNotification.Name(rawValue: "deviceConnected"), object: nil)

    }

//MARK: selector
    
    func noDevice() {
        if Locale.current.languageCode! == "ko"{
            self.loadingButton.setTitle("주변에 HearHere 기기가 없습니다. 기기가 켜져 있는지 확인하시고 이 버튼을 눌러 연결을 다시 시도하십시오. 계속해서 이 문구가 나온다면 앱을 종료 후 다시 실행해주십시오.", for: UIControlState.normal)
        } else {
            self.loadingButton.setTitle("No HearHere device found. Please check your device is turned on. If this message appears repeatedly, please restart the app.", for: UIControlState.normal)
        }
        self.loadingButton.isEnabled = true
        self.connectionState = ConnectionState.NoDevice
        self.soundPlay(fileName: "beepAlert", fileType: "mp3")
    }
    
    func deviceConnectionFailure() {
        if Locale.current.languageCode! == "ko"{
            self.loadingButton.setTitle("HearHere기기를 연결하는데 실패했습니다. 기기를 껐다 켜시고 이 버튼을 눌러 연결을 다시 시도하십시오. 계속해서 이 문구가 나온다면 앱을 종료 후 다시 실행해주십시오.", for: UIControlState.normal)
        } else {
            self.loadingButton.setTitle("Failed to connect to HearHere device. Please reset the device by turning off and on. If this message appears repeatedly, please restart the app.", for: UIControlState.normal)
        }
        self.loadingButton.isEnabled = true
        self.connectionState = ConnectionState.ConnectionFail
        self.soundPlay(fileName: "beepAlert", fileType: "mp3")
    }
    
    func deviceConnected () {
        if Locale.current.languageCode! == "ko"{
            self.loadingButton.setTitle("HearHere기기에 연결했습니다. 네비게이션을 시작하려면 이 버튼을 누르십시오.", for: UIControlState.normal)
        } else {
            self.loadingButton.setTitle("Connected to HearHere device. To start navigation, please press thus button.", for: UIControlState.normal)
        }
        self.loadingButton.isEnabled = true
        self.connectionState = ConnectionState.DeviceConnected
        self.soundPlay(fileName: "deviceConnected", fileType: "mp3")
    }


//MARK: segue

    func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "bluetoothConnected" {
            let vc = segue.destination as! NavigationTableViewController
            vc.route = self.route
        }
    }

}
