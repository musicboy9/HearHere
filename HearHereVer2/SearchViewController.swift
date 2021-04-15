//
//  SearchViewController.swift
//  HearHereVer2
//
//  Created by 고영민 on 2016. 7. 21..
//  Copyright © 2016년 고영민. All rights reserved.
//

import UIKit
import Speech
import MapKit
import CoreLocation
import AVFoundation
import CoreBluetooth


class SearchViewController: UIViewController, CLLocationManagerDelegate, AVAudioRecorderDelegate, CBPeripheralManagerDelegate {
    
//MARK: Variables
    
    var audioPlayer: AVAudioPlayer?
    
    var audioRecorder: AVAudioRecorder?
    
    var soundForMapSearchFileURL: URL?
    
    var speechRecognizer = SFSpeechRecognizer()
    
    var speechText = "" {
        didSet {
            print(speechText)
            mapSearch.searchRegion = self.searchRegionUser
            mapSearch.searchDestination(text: speechText)
        }
    }
    
    var bluetoothPeripheralManager: CBPeripheralManager?
    
    var bluetoothTurnedOn = false {
        didSet {
            if Locale.current.languageCode! == "ko"{
                if self.bluetoothTurnedOn {
                    self.voiceSearchButton.setTitle("목적지를 검색합니다. 화면을 두번 터치한 상태로 알림음이 들린 이후 목적지를 말씀하시고 화면에서 손가락을 떼주세요.", for: UIControlState.normal)
                    self.voiceSearchButton.isEnabled = true
                } else {
                    self.voiceSearchButton.setTitle("블루투스가 꺼져있습니다. 블루투스를 켜고 다시 실행해주십시오.", for: UIControlState.normal)
                    self.voiceSearchButton.isEnabled = false
                }
            }//사용자의 언어가 한국어일 경우 표시되는 버튼의 text
            else{
                if self.bluetoothTurnedOn {
                    self.voiceSearchButton.setTitle("Search for destination. Double tap the screen and stay your finger touching the screen. Say the destination after a beep sound and then release your finger from the screen", for: UIControlState.normal)
                    self.voiceSearchButton.isEnabled = true
                } else {
                    self.voiceSearchButton.setTitle("Bluetooth is turned off. Please turn on the Bluetooth and run the app again", for: UIControlState.normal)
                    self.voiceSearchButton.isEnabled = false
                }
                
            }//사용자의 언어가 한국어가 아닐 경우 표시되는 버튼의 text
        }
    }

    var locationManager = CLLocationManager()
    
    var searchRegionUser = MKCoordinateRegion() // 목적지를 검색할 region. 사용자를 중심으로 하는 5km 너비의 정사각형 형태임.
    
    var userLocation = CLLocation() // 사용자의 location
    
    var mapSearch = MapSearch()
    
    var searchMapItemList = [MKMapItem]() {
        didSet {
            if self.searchMapItemList.count == 1{
                self.routeCreator.destinationItem = self.searchMapItemList[0]
                self.routeCreator.startCoordToMapItem(location: userLocation)
            } else if self.searchMapItemList.count == 2{
                self.routeCreator.destinationItem = self.searchMapItemList[0]
                self.routeCreator.startCoordToMapItem(location: userLocation)
            }
        }
    }
    
    var routeCreator = RouteCreator()
    
    var routeList = [MKRoute]() {
        didSet {
            if self.routeList.count == self.searchMapItemList.count {
                performSegue(withIdentifier: "searchEnd", sender: nil)
            }
        }
    }
    
//MARK: IBOutlet
    
    @IBOutlet weak var voiceSearchButton: UIButton!{
        didSet {
            voiceSearchButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping // Line Breaking Option
        }
    }
    
//MARK: IBAction

    @IBAction func recordButtonDown(_ sender: AnyObject) {
        
        print("recordButtonDown")
        
        self.recorderInitiallize()
        
        self.audioPlayer?.play()
        sleep(1)
        
        self.audioRecorder?.record()
    }
    
    @IBAction func recordButtonUp(_ sender: AnyObject) {
        self.audioRecorder?.stop()
        
        self.voiceSearchButton.isEnabled = false
        
        print(self.soundForMapSearchFileURL)

        let speechRequest = SFSpeechURLRecognitionRequest(url: self.soundForMapSearchFileURL!)
        
        let speechRecognitionTask = self.speechRecognizer?.recognitionTask(with: speechRequest, resultHandler: { (recognitionResult, error) in
            if let tempError = error {
                print("There was an error: \(tempError)")
                self.voiceSearchButton.isEnabled = true
                if Locale.current.languageCode! == "ko"{
                    self.voiceSearchButton.setTitle("검색에 실패했습니다. 다시 검색해주십시오. 목적지를 검색합니다. 화면을 두번 터치한 상태로 알림음이 들린 이후 목적지를 말씀하시고 화면에서 손가락을 떼주세요.", for: UIControlState.normal)
                } else {
                    self.voiceSearchButton.setTitle("Search Failed. Please Search Again. Search for destination. Double tap the screen and stay your finger touching the screen. Say the destination after a beep sound and then release your finger from the screen", for: UIControlState.normal)
                }
            } else {
                if self.speechText != (recognitionResult?.bestTranscription.formattedString)! {
                    self.speechText = (recognitionResult?.bestTranscription.formattedString)!
                    print((recognitionResult?.bestTranscription.formattedString)!)
                }
            }
        })
    }
    
//MARK: selector
    
    func mapSearchSucceeded() {
        if mapSearch.searchTextList.count == 0{
            self.voiceSearchButton.isEnabled = true
            if Locale.current.languageCode! == "ko"{
                self.voiceSearchButton.setTitle("검색결과가 없습니다. 다시 검색해주십시오. 목적지를 검색합니다. 화면을 두번 터치한 상태로 알림음이 들린 이후 목적지를 말씀하시고 화면에서 손가락을 떼주세요.", for: UIControlState.normal)
            } else {
                self.voiceSearchButton.setTitle("No Search Result. Please Search Again. Search for destination. Double tap the screen and stay your finger touching the screen. Say the destination after a beep sound and then release your finger from the screen", for: UIControlState.normal)
            }

        } else {
            if mapSearch.mapItemList.count == 1 {
                self.searchMapItemList = mapSearch.mapItemList
            } else if mapSearch.mapItemList.count > 1 {
                self.searchMapItemList = Array(mapSearch.mapItemList[0..<2])
            }
        }
    }
    
    func routeCreated() {
        self.routeList.append(self.routeCreator.route[0])
        if self.searchMapItemList.count == 2 {
            if self.routeList.count == 1 {
                self.routeCreator.destinationItem = self.searchMapItemList[1]
                self.routeCreator.startCoordToMapItem(location: self.userLocation)
            }
        }
    }
    
//MARK: Segue Function
    func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "searchEnd" {
            let vc = segue.destination as! SearchResultTableViewController
            vc.searchTextList = mapSearch.searchTextList
            vc.searchMapItemList = self.searchMapItemList
            vc.routeList = self.routeList
        }
    }

//MARK: Audio Recording
    
    func recorderInitiallize() {
        
        //AVAudioRecorder initiallizing
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docsDir = dirPaths[0]
        let soundFilePath = docsDir.appending("/soundForMapSearch"+".caf")
        let soundFileURL = NSURL(fileURLWithPath: soundFilePath)
        self.soundForMapSearchFileURL = soundFileURL as URL // 소리를 녹음할 파일의 주소를 결정
        
        let recordSettings =
            [AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue, AVEncoderBitRateKey: 16, AVNumberOfChannelsKey: 2, AVSampleRateKey: 44100.0] as [String : Any]
        //녹음에 필요한 수치 설정
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error{
            print(error)
        }
        do {
            try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch let error {
            print(error)
        }
        
        do {
            try self.audioRecorder = AVAudioRecorder(url: soundFileURL as URL, settings: recordSettings as [String : AnyObject])
        } catch (let error) {
            print(error)
        }
        
        self.audioRecorder?.prepareToRecord()
        
        print("AVAudioRecorder Initiallized")
    }
    
//MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Notification initiallizing
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.mapSearchSucceeded), name: NSNotification.Name(rawValue: "mapSearchTextResultIsReady"), object: nil)
        print("Notification Initiallized")
        
        NotificationCenter.default.addObserver(self, selector: #selector(routeCreated), name: NSNotification.Name(rawValue: "routeCreated"), object: nil)
        
        //location Manager initializing
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            self.locationManager.startUpdatingLocation()
        }
        print("locationManager Initiallized")
        
        //AVAudioPlayer initializing
        
        let alertSound = Bundle.main.path(forResource: "beepAlert", ofType: "mp3") // alertSound을 bundle에 추가함
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: alertSound!)) // audioPlayer에 alertSound를 추가함
        } catch {
            print("error occured")
        }
        self.audioPlayer?.prepareToPlay() // buffer를 미리 추가하는 과정
        
        print("AVAudioPlayer Initiallized")
        
        //CBPeripheralManager initializing
        
        let options = [CBCentralManagerOptionShowPowerAlertKey:0]
        self.bluetoothPeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: options)
        print("CBPeripheralManager Initiallized")
        
    }

//MARK: CLLocationMAnagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        self.userLocation = location! // location이 업데이트될 때마다 userLocation에 업데이트 시켜줌.
        
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.04504504504, longitudeDelta: 0.04504504504))
        self.searchRegionUser = region // 사용자 중심의 정사각형 region을 업데이트.
    }
    
//MARK: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case CBManagerState.poweredOn:
            self.bluetoothTurnedOn = true
        case CBManagerState.poweredOff:
            self.bluetoothTurnedOn = false
        default:
            break
        }
    }
}

