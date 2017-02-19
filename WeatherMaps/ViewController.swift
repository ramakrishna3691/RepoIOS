//
//  ViewController.swift
//  WeatherMaps
//
//  Created by Ramakrishna Bodapati on 18/02/17.
//  Copyright © 2017 Ramakrishna Bodapati. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    fileprivate let collectionViewCellIdentifier = "dayWeatherCollectionViewCell"
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var weatherSummery: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    fileprivate let remoteService = RemoteService()
    fileprivate var weatherDetailsForComingWeek = [RemoteDataRecord]()
    fileprivate var selectedDayWeatherReport = RemoteDataRecord()
    
    lazy var rightBarButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(ViewController.searchButtonSelected(_:)))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        getWeatherDetails()
        configureNavigationBar()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func searchButtonSelected(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showSearchScreen", sender: self)
    }
    
    fileprivate func configureNavigationBar() {
        navigationItem.rightBarButtonItem = rightBarButton
        let userDefaults = UserDefaults.standard
        if let cityName = userDefaults.value(forKey: "City") as? String {
            self.title = cityName
        }
    }
    
    fileprivate func configureView() {
        self.weatherSummery.text = getMinMaxValues(from: selectedDayWeatherReport)
        if let weather = selectedDayWeatherReport[remoteService.weatherKey] as? [RemoteDataRecord], let weatherDetails = weather.first {
            descriptionLabel.text = weatherDetails[remoteService.descriptionKey] as? String
        }
        if let iconName = getIconName(from: selectedDayWeatherReport) {
            remoteService.getIcon(with: iconName, completionHandler: { remoteDataRecord, image in
                DispatchQueue.global(qos: .userInitiated).async {
                    DispatchQueue.main.async {
                        self.weatherImageView.image = image
                    }
                }
            }, errorHandler: { response in
                
            })
        }
    }
    
    fileprivate func getWeatherDetails(for city: String? = nil) {
        remoteService.getWeatherReport(for: city, completionHandler: { [weak self] remotedataRecord, image in
            guard let strongself = self else { return }
            if let remoteRecords = remotedataRecord {
                DispatchQueue.global(qos: .userInitiated).async {
                    DispatchQueue.main.async {
                        strongself.weatherDetailsForComingWeek = remoteRecords
                        strongself.collectionView.reloadData()
                        strongself.selectedDayWeatherReport = remoteRecords[0]
                        strongself.configureView()
                        strongself.configureNavigationBar()
                        strongself.showViews()
                    }
                }
            }
        }, errorHandler: { [weak self] response in
            guard let strongself = self else { return }
            strongself.showAlertForError()
        })
    }
    
    fileprivate func showViews() {
        collectionView.isHidden = false
        weatherSummery.isHidden = false
        weatherImageView.isHidden = false
        descriptionLabel.isHidden = false
    }
    
    fileprivate func showAlertForError() {
        let alert = UIAlertController(title: nil, message: "Could not processed your request", preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(actionOK)
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func getWeekDayName(for index: Int) -> String {
        if index == 0 {
            return "Today"
        }
        let secondInDay = 86400.0
        let date = Date().addingTimeInterval(secondInDay * Double(index))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "eee"
        return dateFormatter.string(from: date).uppercased()
    }
    
    fileprivate func getIconName(from weatherDetails: RemoteDataRecord) -> String? {
        if let weather = weatherDetails[remoteService.weatherKey] as? [RemoteDataRecord], let weatherDetails = weather.first {
            return weatherDetails[remoteService.iconKey] as? String ?? nil
        }
        return nil
    }
    
    fileprivate func getMinMaxValues(from weatherDetails: RemoteDataRecord) -> String? {
        if let weather = weatherDetails[remoteService.tempKey] as? RemoteDataRecord {
            let min = weather[remoteService.minTempKey] as? CGFloat
            let max = weather[remoteService.maxTempKey] as? CGFloat
            return "\(String(describing:Int(max!))) / \(String(describing:Int(min!)))"
        }
        return nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearchScreen" {
            let searchController = segue.destination as! SearchViewController
            searchController.delegate = self
        }
    }
}

fileprivate typealias DayWeatherCollectionView = ViewController
extension DayWeatherCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SearchControllerDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weatherDetailsForComingWeek.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as! DayWeatherCollectionViewCell
        cell.dayLabel.text = getWeekDayName(for: indexPath.row)
        let remoreDataRecord = weatherDetailsForComingWeek[indexPath.row]
        cell.weatherValues.text = getMinMaxValues(from: remoreDataRecord)
        if let iconName = getIconName(from: remoreDataRecord) {
            remoteService.getIcon(with: iconName, completionHandler: { remoteDataRecord, image in
                DispatchQueue.global(qos: .userInitiated).async {
                    DispatchQueue.main.async {
                        cell.weatherImage.image = image
                    }
                }
            }, errorHandler: { response in
                
            })
        }
        cell.backgroundColor = UIColor.clear.withAlphaComponent(0.1 * CGFloat(indexPath.row))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 7, height: collectionView.frame.size.height)
    }
    
    func didSelectCity(name: String) {
        getWeatherDetails(for: name)
    }
}

class DayWeatherCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var weatherValues: UILabel!

}

