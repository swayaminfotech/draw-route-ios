//
//  MapVC.swift
//  DrawRoute
//
//  Created by Swayam Infotech on 01/10/20.
//  Copyright © 2020 Swayam Infotech. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps

class MapVC: UIViewController {

    @IBOutlet var mapView: GMSMapView!
    
    // to zoom map at time location draw
    var mapMarkerArray : [NSMutableDictionary] = []
    var zoomLevel : Float = 6.0
    
    // latitude longitude of source address
    var sourceLatitude : Double = 22.2884
    var sourceLongitude : Double = 70.7709
    
    // latitude longitude of destination address
    var destinationLatitude : Double = 22.2857
    var destinationLongitude : Double = 70.7710
    
    var locationManager : CLLocationManager = CLLocationManager()

    // for animate the route
    var arrRoutes = [NSDictionary]()
    var path = GMSPath()
    var positionInRoute: UInt = 0
    var animationPath = GMSMutablePath()
    var animationPolyline = GMSPolyline()
    var timerAnimation: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        
        // adding marker on map
        self.addmarker(latitude: sourceLatitude, longitude: sourceLongitude, imageName: "ic_map_pin", zIndex: 0, snippet: "source_address".localized)
        self.addmarker(latitude: destinationLatitude, longitude: destinationLongitude, imageName: "ic_map_pin", zIndex: 0,snippet: "destination_address".localized)
        
        findPath()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.locationMangerStart()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        locationManager.stopUpdatingLocation()
    }
    
    // to start location manager update
    func locationMangerStart() {

        let status = CLLocationManager.authorizationStatus()
        if(status == CLAuthorizationStatus.notDetermined) {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }else {

            if(status == CLAuthorizationStatus.authorizedWhenInUse || status == CLAuthorizationStatus.authorizedAlways) {

                locationManager.startUpdatingLocation()

            }else if(status != CLAuthorizationStatus.authorizedWhenInUse || status != CLAuthorizationStatus.authorizedAlways) {
                
                let settingsAction = UIAlertAction(title: "setting".localized, style: .default) { (action) in
                    if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) {
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            
                            if #available(iOS 10.0, *) {
                                UIApplication.shared.open(settingsUrl, completionHandler: nil)
                            } else {
                                UIApplication.shared.openURL(settingsUrl)
                            }
                        }
                    }
                }
                let closeAction = UIAlertAction(title: "close".localized, style: .default, handler: nil)

                Alert.shared.ShowAlert(title: "location_disabled_title", message: "location_disabled_message", in: self, withAction: [settingsAction , closeAction], addCloseAction: false)

            } else {
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    // to add marker on map
    func addmarker(latitude: Double, longitude: Double, imageName: String, zIndex: Int32 , snippet : String){

        if latitude != 0.0 && longitude != 0.0 {

            let markerView = UIImageView(image: UIImage(named: imageName))
            markerView.frame = CGRect(x: markerView.frame.origin.x, y: markerView.frame.origin.y, width: 30, height: 30)
            
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            marker.map = mapView
            marker.iconView = markerView
            marker.snippet = snippet
            marker.zIndex = zIndex
            
            let currentLocationMarker: NSMutableDictionary = NSMutableDictionary()
            currentLocationMarker.setValue(marker, forKey: "marker")
            self.mapMarkerArray.append(currentLocationMarker)
            
            focusOnMap()
        }
    }
    
    // to draw path API call
    func findPath() {

        if (Util.isInternetAvailable()) {
            
            let origin  = "\(self.sourceLatitude),\(self.sourceLongitude)"
            let destion = "\(self.destinationLatitude),\(self.destinationLongitude)"
            
            let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destion)&key=\(googlePlaceAPIKey)"
            
            ServerAPIs.getRequest(apiUrl: urlString, completion: { (response, error, statusCode) in
                
                print(response)
                if statusCode != 0 {
                
                    let arrRoutes:[NSDictionary] = response["routes"].arrayObject! as! [NSDictionary]
                    self.arrRoutes = arrRoutes

                    if arrRoutes.count != 0 {
                        self.drawRoute(arrRoutes: arrRoutes)
                    }
                    self.locationMangerStart()
                    if let currentCoordinates = self.locationManager.location?.coordinate {
                        self.addmarker(latitude: currentCoordinates.latitude, longitude: currentCoordinates.longitude, imageName: "current_location", zIndex: 0, snippet: "your_location".localized)
                    }
                }
            })
        }else{
            Alert.shared.ShowAlert(title: "internet_not_available", message: "", in: self);
        }
    }

    // to draw route on map
    func drawRoute(arrRoutes : [NSDictionary]) {

        // to draw route between two points
        let overviewPolyline = (arrRoutes[0]).object(forKey:"overview_polyline")as! NSDictionary
        let points = overviewPolyline["points"] as! String

        path = GMSPath(fromEncodedPath : points)!
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 3
        polyline.strokeColor = .black
        polyline.map = self.mapView
        
        self.focusOnMap()
        
        // to start animation between two points
        self.timerAnimation = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(startRouteAnimation), userInfo: nil, repeats: true)
    }

    // animation timer action
    @objc func startRouteAnimation() {

        positionInRoute += 1

        if(positionInRoute >= path.count()){
            positionInRoute = 0
            animationPath = GMSMutablePath()
            animationPolyline.map = nil
        }

        animationPath.add(path.coordinate(at: positionInRoute))
        animationPolyline.path = animationPath
        animationPolyline.strokeColor = theamColor
        animationPolyline.strokeWidth = 4
        animationPolyline.map = self.mapView
    }
    
    // to focus on the map
    func focusOnMap() {
        // bounds of the path , current location and other markers.
        var bounds = GMSCoordinateBounds(path: self.path)
        if let currentLocation = locationManager.location?.coordinate {
            bounds = bounds.includingCoordinate(currentLocation)
        }
        
        for locationmarker in self.mapMarkerArray {
            let mapMarker = locationmarker["marker"] as? GMSMarker
            bounds = bounds.includingCoordinate((mapMarker?.position)!)
        }
        let update = GMSCameraUpdate.fit(bounds, withPadding: 60)
        mapView.animate(with: update)
    }
}

// location manager delegate method
extension MapVC : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // add delay for the map, thus the user can move and then focus on the map
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.focusOnMap()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Util.printLog(error.localizedDescription, "Error while updating location ")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationMangerStart()
    }
}
