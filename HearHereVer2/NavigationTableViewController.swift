//
//  NavigationTableViewController.swift
//  HearHereVer2
//
//  Created by 고영민 on 2016. 8. 1..
//  Copyright © 2016년 고영민. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class NavigationTableViewController: UITableViewController, CLLocationManagerDelegate, DZBluetoothSerialDelegate {
    
//MARK: variables
    
    private var refreshPeriod:TimeInterval = 0.1
    private var timer: Timer?
    
    var locationManager = CLLocationManager()
    
    var route = MKRoute()
    
    var checkPoints = [MKPointAnnotation]() {
        didSet {
            print(checkPoints)
            if checkPoints.count != 0 {
                startNavigating()
            }
        }
    }
    
    var checkPointIndex = 0
    
    var currentCheckpoint = MKPointAnnotation()
    
    var userLocation = CLLocation(latitude: 0.0, longitude: 0.0)

    var orientation = CGFloat(0)
    
    var audioSamplePlayer = AudioSamplePlayer()
    
//MARK: ViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //location Manager initializing
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            self.locationManager.startUpdatingLocation()
        }
        
        routeCreated()
    }
    
//MARK: selector
    
    func routeCreated() {
        /*
        let polyline = self.route.polyline
        print(polyline.pointCount)
        let cStyleCoordinates = UnsafeMutablePointer.allocate(capacity: polyline.pointCount)
        
        polyline.getCoordinates(cStyleCoordinates, range: NSMakeRange(0, polyline.pointCount))
        
        var coordinates: [CLLocationCoordinate2D] = []
        for i in 0..<polyline.pointCount {
            coordinates.append(cStyleCoordinates[i])
        }
        cStyleCoordinates.deallocate(capacity: polyline.pointCount)
        
        var everyAnnotations = [MKPointAnnotation]()
        
        for i in 0..<coordinates.count {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates[i]
            everyAnnotations.append(annotation)
        }
        
        var index = 0
        while (index < (everyAnnotations.count-2))
        {
            let distanceState = closeDistanceStateBetweenThreeAnnotations(annotation1: everyAnnotations[index], annotation2: everyAnnotations[index+1], annotation3: everyAnnotations[index+2])
            if distanceState {
                everyAnnotations.remove(at: index+1)
                index += 1
            }
            else {
                index += 1
            }
        }
        
        var index1 = 0
        while (index1 < (everyAnnotations.count-1))
        {
            let distanceState = farDistanceStateBetweenTwoAnnotations(annotation1: everyAnnotations[index1], annotation2: everyAnnotations[index1+1])
            if distanceState {
                let list = additionalAnnotations(annotation1: everyAnnotations[index1], annotation2: everyAnnotations[index1+1])
                var num = 0
                for annotation in list {
                    everyAnnotations.insert(annotation, at: index1+1+num)
                    num += 1
                }
                index1 = index1 + num + 1
            }
            else {
                index1 += 1
            }
        }
        self.checkPoints = everyAnnotations
 */
    }
    
    func navigate() {
        
        if self.checkPointIndex == checkPoints.count-1 {
            self.audioSamplePlayer.stopSound()
            print("Arrived To Destination")
            stopNavigating()
        }
        else if self.checkPointIndex == 0 {
            currentCheckpoint = checkPoints[0]
            self.checkPointIndex += 1
            print("First Annotation")
        }
        if self.closeDistanceStateBetweenUserAndCheckpoint(myLocation: self.userLocation, checkpoint: currentCheckpoint){
            print("Close to Destination")
            currentCheckpoint = checkPoints[self.checkPointIndex]
            self.checkPointIndex += 1
            self.audioSamplePlayer.stopSound()
            self.audioSamplePlayer.startArrivalSound()
            sleep(1)
            print("alarm sound is being played")
            self.audioSamplePlayer.stopSound()
            self.audioSamplePlayer.startDefaultSound()
        }
        let sourcePos_x = (currentCheckpoint.coordinate.longitude-self.userLocation.coordinate.longitude)/180.0*M_PI*6371000.0
        let sourcePos_y = (currentCheckpoint.coordinate.latitude-self.userLocation.coordinate.latitude)/180.0*M_PI*6371000.0
        let sourcePos = CGPoint(x: -sourcePos_x, y: -sourcePos_y)
        self.audioSamplePlayer.sourcePos = sourcePos
        self.audioSamplePlayer.listenerRotation = self.orientation
    }
    
//MARK: functions
    
    func startNavigating() {
        self.audioSamplePlayer.startDefaultSound()
        self.timer = Timer.scheduledTimer(timeInterval: self.refreshPeriod, target: self, selector: #selector(navigate), userInfo: nil, repeats: true)
    }
    
    func stopNavigating() {
        self.timer?.invalidate()
    }
    
//MARK: CLLocationMAnagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        self.userLocation = location! // location이 업데이트될 때마다 userLocation에 업데이트 시켜줌.

    }

// MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let screenSize = UIScreen.main.bounds.height
        if indexPath.row == 0 {
            return screenSize*0.75
        } else {
            return screenSize*0.25
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "navigationCell", for: indexPath)
        
        
        
        return cell
    }
    
//MARK: DZBluetoothSerialDelegate
    
    func serialHandlerDidReceiveMessage(message: String) {
        let trimmed = message.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        let degree = (trimmed as NSString).floatValue
        var radian = degree * Float(M_PI) / 180.0
        radian += 0.13497
        radian -= Float(M_PI)
        if radian > Float(2*M_PI) {
            radian -= Float(2*M_PI)
        } else if radian < 0.0 {
            radian += Float(2*M_PI)
        }
        self.orientation = CGFloat(radian)
        
        //수정요
    }
    
//MARK: Annotation Functions
    
    func distanceBetweenTwoAnnotations(annotation1:MKPointAnnotation, annotation2: MKPointAnnotation) -> Double {
        
        let dlat12 = abs(annotation1.coordinate.latitude-annotation2.coordinate.latitude)/180.0*M_PI
        let dlon12 = abs(annotation1.coordinate.longitude-annotation2.coordinate.longitude)/180.0*M_PI
        
        let radius = 6371000.0
        
        let temp1 = (dlat12*radius)*(dlat12*radius)
        let temp2 = (dlon12*radius)*(dlon12*radius)
        let temp3 = sqrt(temp1+temp2)
        
        return temp3
    } // 두 annotation사이의 거리를 return
    
    func closeDistanceStateBetweenThreeAnnotations(annotation1: MKPointAnnotation,annotation2: MKPointAnnotation,annotation3: MKPointAnnotation) -> Bool {
        let dlat12 = abs(annotation1.coordinate.latitude-annotation2.coordinate.latitude)/180.0*M_PI
        let dlon12 = abs(annotation1.coordinate.longitude-annotation2.coordinate.longitude)/180.0*M_PI
        
        let dlat23 = abs(annotation2.coordinate.latitude-annotation3.coordinate.latitude)/180.0*M_PI
        let dlon23 = abs(annotation2.coordinate.longitude-annotation3.coordinate.longitude)/180.0*M_PI
        
        let dist12 = self.distanceBetweenTwoAnnotations(annotation1: annotation1, annotation2: annotation2)
        let dist23 = self.distanceBetweenTwoAnnotations(annotation1: annotation2, annotation2: annotation3)
        
        if dist12<10.0 {
            if dist23<10.0 {
                if abs(atan(dlat12/dlon12)-atan(dlat23/dlon23))<(M_PI*2.0/18.0){
                    return true
                }
                if abs(atan(dlat12/dlon12)-atan(dlat23/dlon23))>(M_PI*16.0/18.0){
                    return true
                }
            }
        }
        return false
    } //세개의 체크포인트를 기준으로 가운데 체크포인트가 인접한 두 체크포인트와 10m보다 가깝고 각도가 160도보다 클 경우 false를 return.
    
    func farDistanceStateBetweenTwoAnnotations(annotation1: MKPointAnnotation,annotation2: MKPointAnnotation) -> Bool {
        
        let dist12 = self.distanceBetweenTwoAnnotations(annotation1: annotation1, annotation2: annotation2)
        
        if dist12>30.0 {
            return true
        }
        return false
    } // 두 annotation 사이의 거리가 30m보다 멀 경우 true를 return.
    
    func additionalAnnotations(annotation1: MKPointAnnotation,annotation2: MKPointAnnotation) -> [MKPointAnnotation] {
        let dlat = (annotation2.coordinate.latitude-annotation1.coordinate.latitude)/180.0*M_PI
        let dlon = (annotation2.coordinate.longitude-annotation1.coordinate.longitude)/180.0*M_PI
        
        let distance = self.distanceBetweenTwoAnnotations(annotation1: annotation1, annotation2: annotation2)
        var n = 2
        while (distance / Double(n))>30.0 {
            n += 1
        }
        var returnValue = [MKPointAnnotation]()
        for num in 0..<n-1 {
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = annotation1.coordinate.latitude+dlat/Double(n)*(Double(num)+1.0)*180.0/M_PI
            annotation.coordinate.longitude = annotation1.coordinate.longitude+dlon/Double(n)*(Double(num)+1.0)*180.0/M_PI
            returnValue.append(annotation)
        }
        return returnValue
    } // 두 annotation 사이의 거리를 일정하게 나누어 30m보다 줄어들 때까지 일정한 annotation을 추가해 두 annotation 사이에 일정하게 annotation이 추가된 list를 return.
    
    func closeDistanceStateBetweenUserAndCheckpoint(myLocation: CLLocation, checkpoint: MKPointAnnotation) -> Bool{
        let tempMKPA = MKPointAnnotation()
        tempMKPA.coordinate = myLocation.coordinate
        
        let distance = self.distanceBetweenTwoAnnotations(annotation1: tempMKPA, annotation2: checkpoint)
        if distance < 5.0 {
            return true
        }
        return false
    } // 사용자와 현재 checkpoint사이의 거리가 5m보다 가까울 경우 true를 return.

}
