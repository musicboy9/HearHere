//
//  mapSearch.swift
//  HearHereVer2
//
//  Created by 고영민 on 2016. 7. 23..
//  Copyright © 2016년 고영민. All rights reserved.
//

import Foundation
import MapKit

class MapSearch
{
//MARK: variables
    
    var mapItemList = [MKMapItem]() // searchResponse가 MKMapItem의 list로 들어옴. 검색을 할 때 업데이트
    
    var searchTextList = [(String,String)](){
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "mapSearchTextResultIsReady"), object: nil)
        }
    } // searchAnnotationList를 item.placemark.name과 placemark.description으로 이루어진 String Tuple들의 list로 변환함.
    
    var searchRegion = MKCoordinateRegion() // 사용자 위치를 기준으로 한 정사각형(5km) Region

//MARK: functions
    
    func itemInSquareRegion(item: MKMapItem, region: MKCoordinateRegion) -> Bool {
        let delta = region.span.latitudeDelta
        let latitude = item.placemark.location!.coordinate.latitude
        let longitude = item.placemark.location!.coordinate.longitude
        let c_latitude = region.center.latitude
        let c_longitude = region.center.longitude
        if (latitude<c_latitude+delta/2){
            if (latitude>c_latitude-delta/2){
                if (longitude<c_longitude+delta/2){
                    if (longitude>c_longitude-delta/2){
                        return true
                    }
                }
            }
        }
        return false
    } // item이 region안에 있는지 판단.(region은 square)

//MARK: MapKit function
    
    func searchDestination(text: String?)
    {
        let localSearchRequest = MKLocalSearchRequest.init()
        localSearchRequest.region = searchRegion
        localSearchRequest.naturalLanguageQuery = text! // search하는 text를 설정
        
        let localSearch = MKLocalSearch.init(request: localSearchRequest)
        
        localSearch.start { (localSearchResponse, error) in
            if localSearchResponse != nil {
                var tempTextList = [(String,String)]()
                for mapItem in (localSearchResponse?.mapItems)! as [MKMapItem] {
                    if self.itemInSquareRegion(item: mapItem, region: self.searchRegion) {
                        self.mapItemList.append(mapItem)
                        
                        let newStringData: (String,String)
                        newStringData.0 = mapItem.placemark.name!//장소의 이름
                        
                        var description = mapItem.placemark.description
                        let indexAt = description.range(of: "@")!.lowerBound
                        description = description.substring(to: indexAt)
                        newStringData.1 = description // 장소의 주소
                    
                        tempTextList.append(newStringData)
                    }
                }
                self.searchTextList = tempTextList
            }
        }
    }
    
    /*    var searchAnnotationList = [MKPointAnnotation](){
     didSet {
     searchTextList = convertToText(annotations: self.searchAnnotationList)
     }
     } // searchResponse의 MKMapItem 변수에 대해 annotation을 생성하여 하나씩 append함.
     */
    
    /*
     func convertToText(annotations: [MKAnnotation?]) -> [(String,String)] {
     if annotations.count == 0{
     return [("test1","test2")]
     }
     else{
     var temp_annotations = [MKAnnotation]()
     for annotation in annotations{
     temp_annotations.append(annotation!)
     }
     let annotations = temp_annotations
     var annotationsText = [(String,String)]()
     var text:(String,String)
     for annotation in annotations {
     text.0 = annotation.title!! // 왜 !가 두개 필요?
     text.1 = annotation.subtitle!!
     annotationsText.append(text)
     }
     return annotationsText
     }
     } // annotation의 list를 (String,String)의 list로 바꾸어줌.(이름,주소)
     */
}
