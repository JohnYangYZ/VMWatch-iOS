//
//  NewEC2WatchTableViewController.swift
//  vmwatch
//
//  Created by Tuo Zhang on 2016-10-13.
//  Copyright © 2016 ECE496. All rights reserved.
//

import UIKit

class NewEC2WatchTableViewController: UITableViewController {
    
    var region:String?
    var accessID:String?
    var accessKey:String?
    var instanceID:String?
    let alert = VMWAlertView()
    
    @IBOutlet weak var ec2AccessIDTextField: UITextField!
    @IBOutlet weak var ec2AccessKeyTextField: UITextField!
    @IBOutlet weak var instanceIDTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var regionSelectionButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.submitButton.layer.cornerRadius = 5
        self.submitButton.clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
            case 0:
                return 2
            case 1:
                return 1
            case 2:
                return 1
            default:
                return 0
        }
    }
    
    @IBAction func selectRegion(_ sender: AnyObject) {
        /*Setup alert for photo selection type menu (take photo or choose existing photo)*/
        let optionMenu = UIAlertController(title: nil, message: "Please select region", preferredStyle: .actionSheet)
        
        /*Setup the photo picker*/
        let USEast = UIAlertAction(title: "US East (N. Virginia)", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.region = "us-east-1"
            self.regionSelectionButton.setTitle("us-east-1", for: .normal)
            return
        })
        
        let USWestOne = UIAlertAction(title: "US West (N. California)", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.region = "us-west-1"
            self.regionSelectionButton.setTitle("us-west-1", for: .normal)
            return
        })
        
        let USWestTwo = UIAlertAction(title: "US West (Oregon)", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.region = "us-west-2"
            self.regionSelectionButton.setTitle("us-west-2", for: .normal)
            return
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            self.region = nil
            self.regionSelectionButton.setTitle("Please select region", for: .normal)
            return
        })
        
        /*Add all actions*/
        optionMenu.addAction(USEast)
        optionMenu.addAction(USWestOne)
        optionMenu.addAction(USWestTwo)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    @IBAction func doSubmit(_ sender: AnyObject) {
        do{
            let parser = VMWEC2InputParser()
            try parser.accessIDParser(input: ec2AccessIDTextField.text)
            try parser.secretKeyParser(input: ec2AccessKeyTextField.text)
            try parser.instanceIDParser(input: instanceIDTextField.text)
            try parser.regionParser(input: self.region)
            
            let ec2Result : EC2WatchResultViewController = EC2View.instantiateViewController(withIdentifier: "ec2result") as! EC2WatchResultViewController
            ec2Result.accessID = ec2AccessIDTextField.text!
            ec2Result.accessKey = ec2AccessKeyTextField.text!
            ec2Result.instanceID = instanceIDTextField.text!
            ec2Result.region = self.region
            ec2Result.hidesBottomBarWhenPushed = true
            self.navigationController!.navigationBar.tintColor = UIColor.white
            self.navigationController?.pushViewController(ec2Result, animated: true)
        } catch VMWEC2InputParserError.EmptyAccessKey {
            self.present(
                self.alert.showAlertWithOneButton(
                    title: "Error",
                    message: "Access ID is empty",
                    actionButton: "OK"
                ),
                animated: true,
                completion: nil
            )
        } catch VMWEC2InputParserError.EmptySecretKey {
            self.present(
                self.alert.showAlertWithOneButton(
                    title: "Error",
                    message: "Secret key is empty",
                    actionButton: "OK"
                ),
                animated: true,
                completion: nil
            )
        } catch VMWEC2InputParserError.EmptyInstanceID {
            self.present(
                self.alert.showAlertWithOneButton(
                    title: "Error",
                    message: "Instance ID is empty",
                    actionButton: "OK"
                ),
                animated: true,
                completion: nil
            )
        } catch VMWEC2InputParserError.EmptyRegion {
            self.present(
                self.alert.showAlertWithOneButton(
                    title: "Error",
                    message: "Please select a region",
                    actionButton: "OK"
                ),
                animated: true,
                completion: nil
            )
        } catch let error as NSError {
            NSLog("Error with request: \(error)")
            self.present(
                self.alert.showAlertWithOneButton(
                    title: "Error",
                    message: "Unexpected Error",
                    actionButton: "OK"
                ),
                animated: true,
                completion: nil
            )
        }
    }
    
//    func storeAccessCredential(){
//        let testParams = [
//            "accessid" as NSObject: self.accessID as AnyObject,
//            "accesskey" as NSObject: self.accessKey as AnyObject,
//            "instanceid" as NSObject: self.instanceID as AnyObject,
//            "region" as NSObject: self.region as AnyObject
//            ] as [NSObject:AnyObject]
//        
//        PFCloud.callFunction(inBackground: "ec2UserDataStore", withParameters: testParams) { (response, ec2StoreError) in
//            print("done")
//        }
//    }
    
    func storeHistory(){
        let history = VMWEC2HistoryStorage()
        do{
            try history.deleteHistoryRecord(accessID: self.accessID!, accessKey: self.accessKey!, instanceID: self.instanceID!, region: self.region!)
            try history.storeEC2History(accessID: self.accessID!, accessKey: self.accessKey!, instanceID: self.instanceID!, region: self.region!)
        } catch VMWEC2CoreDataStorageError.DatabaseStoreError {
            NSLog("Could not save the history data due to database issue")
        } catch VMWEC2CoreDataStorageError.DatabaseDeleteError {
            NSLog("Fail to remove previous history data due to database issue")
        } catch {
            NSLog("Unexpected database issue")
        }
    }
    
    @IBAction func startOCR(_ sender: Any) {
        
    }
}

extension String {
    func sha1() -> String {
        let data = self.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}
