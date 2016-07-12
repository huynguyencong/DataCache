//
//  ViewController.swift
//  CacheDemo
//
//  Created by Nguyen Cong Huy on 7/4/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit
import DataCache

class ViewController: UIViewController {

    @IBOutlet weak var keyTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func readButtonTouched(sender: AnyObject) {
        let key = keyTextField.text!
        let cachedString = DataCache.defaultCache.readStringForKey(key)
        valueTextField.text = cachedString
    }

    @IBAction func writeButtonTouched(sender: AnyObject) {
        let string = valueTextField.text!
        let key = keyTextField.text!
        DataCache.defaultCache.writeObject(string, forKey: key)
    }
    
    func writeImageToCache() {
        let image = UIImage(named: "dog.jpg")
        DataCache.defaultCache.writeImage(image!, forKey: "haha")
    }
    
    func readImageFromCacheAndShow() {
        let image = DataCache.defaultCache.readImageForKey("haha")
        imageView.image = image
    }
}

