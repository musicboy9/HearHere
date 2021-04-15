//
//  SearchResultTableViewController.swift
//  HearHereVer2
//
//  Created by 고영민 on 2016. 7. 31..
//  Copyright © 2016년 고영민. All rights reserved.
//

import UIKit
import MapKit

class SearchResultTableViewController: UITableViewController{
    
    var searchTextList = [(String,String)]()
    
    var searchMapItemList = [MKMapItem]()
    
    var routeList = [MKRoute]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.isScrollEnabled = false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if self.searchTextList.count > 1{
            return 3
        }
        else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResult", for: indexPath)
        
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        if searchTextList.count == 1 {
            if indexPath.row == 0 {
                if Locale.current.languageCode! == "ko"{
                    cell.textLabel?.text = searchTextList[0].0 + ". \(Int(self.routeList[0].distance)) 미터 떨어져있고, 예상 이동 시간은 \(Int(self.routeList[0].expectedTravelTime/60.0))분입니다. 이 목적지가 맞으시다면 이 버튼을 눌러주십시오."
                } else {
                    cell.textLabel?.text = searchTextList[0].0 + ". Distance of the route is \(Int(self.routeList[0].distance)) meters and estimated time is \(Int(self.routeList[0].expectedTravelTime/60.0))minutes. If this destination is correct, please press this button"
                }
            }
            else if indexPath.row == 1 {
                if Locale.current.languageCode! == "ko"{
                    cell.textLabel?.text = "원하는 결과가 없으시다면 이 부분을 눌러 재검색해주십시오. 구체적인 목적지명으로 검색할수록 정확도가 높아집니다."
                }
                else {
                    cell.textLabel?.text = "If the result is not appropriate, please press this part to search again. Searching with a specific name makes the result more accurate"
                }
            }
        }
                
        else if searchTextList.count > 1 {
            if indexPath.row == 0 {
                if Locale.current.languageCode! == "ko"{
                    cell.textLabel?.text = searchTextList[0].0 + ". \(Int(self.routeList[0].distance)) 미터 떨어져있고, 예상 이동 시간은 \(Int(self.routeList[0].expectedTravelTime/60.0))분입니다. 이 목적지가 맞으시다면 이 버튼을 눌러주십시오."
                } else {
                    cell.textLabel?.text = searchTextList[0].0 + ". Distance of the route is \(Int(self.routeList[0].distance)) meters and estimated time is \(Int(self.routeList[0].expectedTravelTime/60.0))minutes. If this destination is correct, please press this button"
                }
            }
            else if indexPath.row == 1 {
                if Locale.current.languageCode! == "ko"{
                    cell.textLabel?.text = searchTextList[1].0 + ". \(Int(self.routeList[1].distance)) 미터 떨어져있고, 예상 이동 시간은 \(Int(self.routeList[1].expectedTravelTime/60.0))분입니다. 이 목적지가 맞으시다면 이 버튼을 눌러주십시오."
                } else {
                    cell.textLabel?.text = searchTextList[1].0 + ". Distance of the route is \(Int(self.routeList[1].distance)) meters and estimated time is \(Int(self.routeList[1].expectedTravelTime/60.0))minutes. If this destination is correct, please press this button"
                }
            }
            else if indexPath.row == 2 {
                if Locale.current.languageCode! == "ko"{
                    cell.textLabel?.text = "원하는 결과가 없으시다면 이 부분을 눌러 재검색해주십시오. 구체적인 목적지명으로 검색할수록 정확도가 높아집니다."
                }
                else {
                    cell.textLabel?.text = "If the result is not appropriate, please press this part to search again. Searching with a specific name makes the result more accurate"
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let screenSize = UIScreen.main.bounds.height
        if self.searchTextList.count == 1 {
            return screenSize*0.5
        } else {
            return screenSize/3.0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        print(indexPath.row)
        
        if self.searchTextList.count == 1 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: "bluetoothConnecting", sender: self)
            } else if indexPath.row == 1 {
                print("searchAgain")
                performSegue(withIdentifier: "searchAgain", sender: self)
            }
        } else if self.searchTextList.count > 1 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: "bluetoothConnecting", sender: self)
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: "bluetoothConnecting", sender: self)
            } else if indexPath.row == 2 {
                print("searchAgain")
                performSegue(withIdentifier: "searchAgain", sender: self)
            }
        }
    }

// MARK: segue

    func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if let cell = sender as? UITableViewCell {
            if segue.identifier == "bluetoothConnecting" {
                print(1)
                let index = self.tableView.indexPath(for: cell)?.row
                let vc = segue.destination as? BluetoothConnectionViewController
                vc?.route = self.routeList[index!]
            }
        }
    }
 
}
