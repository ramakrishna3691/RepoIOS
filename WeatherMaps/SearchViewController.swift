//
//  SearchViewController.swift
//  WeatherMaps
//
//  Created by Ramakrishna Bodapati on 18/02/17.
//  Copyright © 2017 Ramakrishna Bodapati. All rights reserved.
//

import UIKit

protocol SearchControllerDelegate: class {
    func didSelectCity(name: String)
}

class SearchViewController: UIViewController {
    weak var delegate: SearchControllerDelegate?
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBAction func searchButtonSelected(_ sender: UIBarButtonItem) {
        if let searchText = searchTextField.text, searchText.characters.count > 2 {
        delegate?.didSelectCity(name: searchText)
        }
        dismiss(animated: true, completion: nil)
    }
}

