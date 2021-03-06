//
//  StudentsTableViewController.swift
//  OnTheMap
//
//  Created by Jeff Newell on 11/12/15.
//  Copyright © 2015 Jeff Newell. All rights reserved.
//

import UIKit

class StudentsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DataObserver {
    
    let CELL_ID = "StudentCell"
    
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: Lifecycle overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        StudentLocations.sharedInstance.registerObserver(self)
        if StudentLocations.sharedInstance.isPopulated() {
            tableView.reloadData()
        } else {
            StudentLocations.sharedInstance.fetchLocations() { success in
                if !success {
                    dispatch_async(dispatch_get_main_queue()){
                        self.downloadFailureAlert()
                    }
                }
            }
        }
    }
    //MARK: helper functions
    func downloadFailureAlert() {
        let alert = UIAlertController(title: "Data Alert", message: "Student Data Failed to Download", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: Actions
    @IBAction func addNewPinAction(sender: UIBarButtonItem) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("PinPostingViewController") as! PinPostingViewController
        presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBAction func refreshDataAction(sender: UIBarButtonItem) {
        StudentLocations.sharedInstance.fetchLocations(){ success in
            if !success {
                dispatch_async(dispatch_get_main_queue()){
                    self.downloadFailureAlert()
                }
            }
        }

    }
    
    @IBAction func logoutAction(sender: UIBarButtonItem) {
        UdacityUserCredentials.sharedInstance.logout() { (_,_,_) in }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_ID)!
        let locations = StudentLocations.sharedInstance.locations()
        cell.textLabel?.text = "\(locations[indexPath.row].firstName ?? "") \(locations[indexPath.row].lastName ?? "")"
        cell.detailTextLabel?.text = "@\(locations[indexPath.row].mapString ?? "")"
        //cell.backgroundView = UIImage(named: ??)
        //cell.selectedBackgroundView = UIImage(named: ??)
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StudentLocations.sharedInstance.locations().count
    }
    
    //DATA OBSERVER
    func refresh() {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
    func add(newItem: Any, indexPath: NSIndexPath) {
        if let _ = newItem as? StudentLocation {
            tableView.reloadData()
        }
    }
    //MARK UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let app = UIApplication.sharedApplication()
        let locations = StudentLocations.sharedInstance.locations()
        guard let tryUrlString = locations[indexPath.row].mediaURL else {
            return
        }
        if let url = RESTApiHelpers.forgivingUrlFromString(tryUrlString) {
            app.openURL(url)
        }
    }
}
