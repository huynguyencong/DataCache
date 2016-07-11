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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func readButtonTouched(sender: AnyObject) {
        valueTextField.text = DataCache.defaultCache.readStringForKey(keyTextField.text!)
    }

    @IBAction func writeButtonTouched(sender: AnyObject) {
        DataCache.defaultCache.writeString(valueTextField.text!, forKey: keyTextField.text!)
    }
}

