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
    
    static let imageKey = "imageKey"

    @IBOutlet weak var keyTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func readButtonTouched(_ sender: AnyObject) {
        let key = keyTextField.text!
        let cachedString = DataCache.instance.readString(forKey: key)
        valueTextField.text = cachedString
    }

    @IBAction func writeButtonTouched(_ sender: AnyObject) {
        let string = valueTextField.text!
        let key = keyTextField.text!
        DataCache.instance.write(object: string as NSCoding, forKey: key)
    }
    
    func writeImageToCache() {
        let image = UIImage(named: "dog.jpg")
        DataCache.instance.write(image: image!, forKey: ViewController.imageKey)
    }
    
    func readImageFromCacheAndShow() {
        let image = DataCache.instance.readImageForKey(key: ViewController.imageKey)
        imageView.image = image
    }
}

