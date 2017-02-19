//
//  RemoteService.swift
//  WeatherMaps
//
//  Created by Ramakrishna Bodapati on 18/02/17.
//  Copyright © 2017 Ramakrishna Bodapati. All rights reserved.
//

import UIKit
import CoreLocation

typealias RemoteDataRecord = [String: AnyObject]
typealias CompletionHandler = (_ records: [RemoteDataRecord]?, _ image: UIImage?) -> Void
typealias RemoteErrorHandler = (URLResponse?) -> Void
typealias LocationCoordinate = (latitude: String, longitude: String)

class RemoteService {
    let weatherKey = "weather"
    let iconKey = "icon"
    let tempKey = "temp"
    let listKey = "list"
    let minTempKey = "min"
    let maxTempKey = "max"
    let cityTempKey = "city"
    let cityNameTempKey = "name"
    let descriptionKey = "description"
    fileprivate let hostURL = "http://api.openweathermap.org/data/2.5/forecast/daily?"
    fileprivate let weatherURLForCoordinates = "http://api.openweathermap.org/data/2.5/forecast/daily?units=imperial&cnt=7&"
    fileprivate let iconHostURL = "http://openweathermap.org/img/w/"
    fileprivate let owpAppID = "b6a099de9ccb0cff7729918de1f6d5d4"
    fileprivate var urlSession: URLSession = URLSession.shared
    
    /*
     "http://api.openweathermap.org/data/2.5/forecast/daily?units=imperial&cnt=7&lat=%f&lon=%f"
 */
    fileprivate func createWeatherURL(for city: String, locationCoordinate: LocationCoordinate? = nil) -> String {
        var urlStringToReturn: String
        if let locationCoordinate = locationCoordinate {
            urlStringToReturn = "\(weatherURLForCoordinates)lat=\(locationCoordinate.latitude)&lon=\(locationCoordinate.longitude)"
        } else {
            urlStringToReturn = "\(hostURL)q=\(city)"
        }
        return "\(urlStringToReturn)&APPID=\(owpAppID)"
    }
    
    fileprivate func createURLRequest(for url: String) -> URLRequest{
        var urlRequest = URLRequest(url: URL(string: url)!)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        return urlRequest
    }
    
    func getIcon(with iconName: String, completionHandler: @escaping CompletionHandler, errorHandler: @escaping RemoteErrorHandler) {
        sendRemoteRequest(with: "\(iconHostURL)10d.png", completionHandler: completionHandler, errorHandler: errorHandler)
    }
    
    func getWeatherReport(for city: String? = nil, completionHandler: @escaping CompletionHandler, errorHandler: @escaping RemoteErrorHandler) {
        if let city = city {
            sendRemoteRequest(with: createWeatherURL(for: city), completionHandler: completionHandler, errorHandler: errorHandler)
        } else {
            let userDefaults = UserDefaults.standard
            if let cityName = userDefaults.value(forKey: "City") as? String {
                sendRemoteRequest(with: createWeatherURL(for: cityName), completionHandler: completionHandler, errorHandler: errorHandler)
            } else if let curentLocation = getCurrentLocation() {
                let locationCoordinate = (String(describing:(curentLocation.latitude)), String(describing:(curentLocation.latitude)))
                sendRemoteRequest(with: createWeatherURL(for: "", locationCoordinate: locationCoordinate), completionHandler: completionHandler, errorHandler: errorHandler)
            }
        }
    }
    
    func sendRemoteRequest(with urlString: String, completionHandler: @escaping CompletionHandler, errorHandler: @escaping RemoteErrorHandler) {
        let urlResuest = createURLRequest(for: urlString)
        let task = urlSession.dataTask(with: urlResuest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let response = response {
                let statusCode = (response as! HTTPURLResponse).statusCode
                switch (statusCode) {
                case 200, 201:
                    if let json = try? JSONSerialization.jsonObject(with: data!, options: [.allowFragments]) as! RemoteDataRecord {
                        completionHandler(json[self.listKey] as? [RemoteDataRecord], nil)
                        self.saveCityDetails(with: json[self.cityTempKey] as? RemoteDataRecord ?? nil)
                    } else if let image = UIImage(data: data!) {
                        completionHandler(nil, image)
                    } else {
                        errorHandler(response)
                    }
                    break
                default:
                    errorHandler(response)
                }
            } else {
                errorHandler(response)
            }
        })
        task.resume()
    }
    
    fileprivate func getCurrentLocation() -> CLLocationCoordinate2D? {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        let location = locationManager.location
        return location?.coordinate
    }
    
    fileprivate func saveCityDetails(with details: RemoteDataRecord?) {
        guard let details = details else { return }
        let userDefaults = UserDefaults.standard
        userDefaults.set(details[cityNameTempKey], forKey: "City")
    }
    
}
