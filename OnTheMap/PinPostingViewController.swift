//
//  PinPostingViewController.swift
//  OnTheMap
//
//  Created by Jeff Newell on 11/13/15.
//  Copyright © 2015 Jeff Newell. All rights reserved.
//

import Foundation
import MapKit

class PinPostingViewController: UIViewController, MKMapViewDelegate, UITextViewDelegate, DataObserver {
    
    @IBOutlet weak var submitPinView: UIView!
    @IBOutlet weak var findPinView: UIView!
    
    @IBOutlet weak var mediaURLTextView: UITextView!
    @IBOutlet weak var locationEntryTextView: UITextView!
    @IBOutlet weak var mainMap: MKMapView!
    
    var tapRecognizer: UITapGestureRecognizer?
    //var keyboardAdjusted = false
    
    let MAP_LOCAL_ZOOM_WIDTH = 2000.0
    
    let placeholderTextMap = [1: "Enter Your Location Here", 2: "Enter a Link to Share Here"]
    
    var currentPinLatitude: CLLocationDegrees?
    var currentPinLongitude: CLLocationDegrees?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        StudentLocations.sharedInstance.registerObserver(self)
        
        //Prepare the textviews with Placeholder texts
        locationEntryTextView.delegate = self
        mediaURLTextView.delegate = self
        locationEntryTextView.tag = 1
        locationEntryTextView.text = placeholderTextMap[locationEntryTextView.tag]!
        locationEntryTextView.textColor = UIColor.lightGrayColor()
        mediaURLTextView.tag = 2
        mediaURLTextView.text = placeholderTextMap[mediaURLTextView.tag]!
        mediaURLTextView.textColor = UIColor.lightGrayColor()
        //
        tapRecognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        tapRecognizer?.numberOfTapsRequired = 1
        
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        findPinView.hidden = false
        submitPinView.hidden = true
        view.addGestureRecognizer(tapRecognizer!)
        //registerForKeyboardNotifications()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        view.removeGestureRecognizer(tapRecognizer!)
        //unregisterForKeyboardNotifications()
    }

   
    @IBAction func findOnTheMap() {
        let geoText = locationEntryTextView.text
        let g = CLGeocoder()
        g.geocodeAddressString(geoText) { (placemarks, error) in
            if error == nil {
                if placemarks!.count > 0 {
                    let place = placemarks![0]
                    let loc = place.location
                    if let coord2ds = loc?.coordinate {
                        //create an annotation and add to map...
                        self.currentPinLatitude = coord2ds.latitude
                        self.currentPinLongitude = coord2ds.longitude
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = coord2ds
                        self.mainMap.addAnnotation(annotation)
                        self.mainMap.centerCoordinate = coord2ds
                        self.mainMap.region = MKCoordinateRegionMakeWithDistance(coord2ds,
                            self.MAP_LOCAL_ZOOM_WIDTH, self.MAP_LOCAL_ZOOM_WIDTH)
                        //hide the find button, open the map
                        self.findPinView.hidden = true
                        self.submitPinView.hidden = false
                    }
                }
            } else {
                let alert = UIAlertController()
                alert.title = "Location Not Found:"
                let okAction = UIAlertAction(title: "\(geoText)", style: .Default, handler: nil)
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    @IBAction func submitPinAction(sender: UIButton) {
        
        StudentLocations.sharedInstance.checkForExistingLocationForStudent() { (success, errMsg, hasExisting) in
            if let exists = hasExisting where exists == true {
                dispatch_async(dispatch_get_main_queue()) {
                    let alert = UIAlertController()
                    let okAction = UIAlertAction(title: "Add Additional", style: .Destructive ) { action in
                        //TODO: REALLY submit a new pin to the server
                        self.saveNewLocation()
                    }
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                    alert.addAction(okAction)
                    alert.addAction(cancelAction)
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), { self.saveNewLocation() })
            }
        }
    }
    
    func saveNewLocation() {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        guard let uid = app.UdacityUserId else {
            //TODO: tell user didn't work..
            return
        }
        guard let lat = currentPinLatitude, let lon = currentPinLongitude else {
            //TODO: tell user could not map your location..
            return
        }
        var newLocation = StudentLocation()
        newLocation.objectId = uid
        newLocation.latitude =  Float(lat)
        newLocation.longitude = Float(lon)
        newLocation.mapString = locationEntryTextView.text
        newLocation.mediaURL = mediaURLTextView.text
        
        
    }
    
    @IBAction func cancelAction(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Mark: DATA OBSERVER
    func refresh() { }
    func add(newItem: AnyObject, indexPath: NSIndexPath) {
        //TODO: some sort of feedback that the data was saved to the
    }
    
    //Mark: UITextViewDelegates
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.textColor == UIColor.lightGrayColor() {
            textView.text = nil
            textView.textColor = UIColor.whiteColor()
        }
    }
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholderTextMap[textView.tag]
            textView.textColor = UIColor.lightGrayColor()
        }
    }
    
    
    //MARK: helper methods
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
//    func keyboardWillShow(notification: NSNotification) {
//        if !keyboardAdjusted {
//            self.view.superview?.frame.origin.y -= getKeyboardHeight(notification)/2
//            keyboardAdjusted = true
//        }
//    }
//    func keyboardWillHide(notification: NSNotification) {
//        if keyboardAdjusted {
//            self.view.superview?.frame.origin.y += getKeyboardHeight(notification)/2
//            keyboardAdjusted = false
//        }
//    }
//    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
//        let userInfo = notification.userInfo
//        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
//        return keyboardSize.CGRectValue().height
//    }
//    
//    func registerForKeyboardNotifications(){
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
//    }
//    func unregisterForKeyboardNotifications(){
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
//    }

}