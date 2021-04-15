//
//  RouteCreator.swift
//  HearHereVer2
//
//  Created by 고영민 on 2016. 8. 3..
//  Copyright © 2016년 고영민. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class RouteCreator {
    
//MARK: variables
    
    var startItem = MKMapItem() {
        didSet {
            self.calculateRoute()
        }
    }
    
    var destinationItem = MKMapItem()
    
    var geocoder = CLGeocoder()
    
    var route = [MKRoute]() {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "routeCreated"), object: nil)
        }
    }
    
//MARK: functions
    
    func startCoordToMapItem(location: CLLocation)
    {
        self.geocoder.reverseGeocodeLocation(location) { (placemarks, _) in
            if (placemarks?.count)! > 0{
                let startPlacemark = placemarks![0]
                self.startItem = MKMapItem(placemark: MKPlacemark(placemark: startPlacemark))
            }
        }
    }
    
    func calculateRoute(){
        let request: MKDirectionsRequest = MKDirectionsRequest()
        
        request.source = self.startItem
        request.destination = self.destinationItem
        
        request.requestsAlternateRoutes = true
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate (completionHandler: {
            (response: MKDirectionsResponse?, error: NSError?) in
            if let routeResponse = response?.routes {
                self.route = routeResponse
            }
            else {
                print(error)
            }
        } as! MKDirectionsHandler)
    }
}
