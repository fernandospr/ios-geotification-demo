//
//  GeotificationsViewController.swift
//  Geotify
//
//  Created by Ken Toh on 24/1/15.
//  Copyright (c) 2015 Ken Toh. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

let kSavedItemsKey = "savedItems"

class GeotificationsViewController: UIViewController, AddGeotificationsViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate {

  @IBOutlet weak var mapView: MKMapView!

  var geotifications = [Geotification]()
  let locationManager = CLLocationManager() // Add this statement

  override func viewDidLoad() {
    super.viewDidLoad()
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    loadAllGeotifications()
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "addGeotification" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddGeotificationViewController
      vc.delegate = self
    }
  }
  
  func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    mapView.showsUserLocation = (status == .AuthorizedAlways)
  }

  // MARK: Loading and saving functions

  func loadAllGeotifications() {
    geotifications = []

    if let savedItems = NSUserDefaults.standardUserDefaults().arrayForKey(kSavedItemsKey) {
      for savedItem in savedItems {
        if let geotification = NSKeyedUnarchiver.unarchiveObjectWithData(savedItem as! NSData) as? Geotification {
          addGeotification(geotification)
        }
      }
    }
  }

  func saveAllGeotifications() {
    UIApplication.sharedApplication().cancelAllLocalNotifications()
    
    var items = NSMutableArray()
    for geotification in geotifications {
      let item = NSKeyedArchiver.archivedDataWithRootObject(geotification)
      items.addObject(item)
      
      scheduleLocalNotificationWithGeotification(geotification)
    }
    NSUserDefaults.standardUserDefaults().setObject(items, forKey: kSavedItemsKey)
    NSUserDefaults.standardUserDefaults().synchronize()
  }
  
  func scheduleLocalNotificationWithGeotification(geotification: Geotification) {
    let locNotification = UILocalNotification()
    locNotification.alertBody = geotification.note
    locNotification.regionTriggersOnce = false
    locNotification.region = CLCircularRegion(center: geotification.coordinate,
                                              radius: geotification.radius,
                                          identifier: geotification.identifier)
    locNotification.region.notifyOnEntry = EventType.OnEntry == geotification.eventType;
    locNotification.region.notifyOnExit = !locNotification.region.notifyOnEntry
    locNotification.soundName = "Default";
    UIApplication.sharedApplication().scheduleLocalNotification(locNotification)
  }

  // MARK: Functions that update the model/associated views with geotification changes

  func addGeotification(geotification: Geotification) {
    geotifications.append(geotification)
    mapView.addAnnotation(geotification)
    addRadiusOverlayForGeotification(geotification)
    updateGeotificationsCount()
  }

  func removeGeotification(geotification: Geotification) {
    if let indexInArray = find(geotifications, geotification) {
      geotifications.removeAtIndex(indexInArray)
    }

    mapView.removeAnnotation(geotification)
    removeRadiusOverlayForGeotification(geotification)
    updateGeotificationsCount()
  }

  func updateGeotificationsCount() {
    title = "Geotifications (\(geotifications.count))"
    navigationItem.rightBarButtonItem?.enabled = (geotifications.count < 20)
  }

  // MARK: AddGeotificationViewControllerDelegate

  func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
    controller.dismissViewControllerAnimated(true, completion: nil)
    let clampedRadius = (radius > locationManager.maximumRegionMonitoringDistance) ? locationManager.maximumRegionMonitoringDistance : radius
    
    let geotification = Geotification(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
    addGeotification(geotification)
    
    saveAllGeotifications()
  }

  // MARK: MKMapViewDelegate

  func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
    let identifier = "myGeotification"
    if annotation is Geotification {
      var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true
        var removeButton = UIButton.buttonWithType(.Custom) as! UIButton
        removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        removeButton.setImage(UIImage(named: "DeleteGeotification")!, forState: .Normal)
        annotationView?.leftCalloutAccessoryView = removeButton
      } else {
        annotationView?.annotation = annotation
      }
      return annotationView
    }
    return nil
  }

  func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
    if overlay is MKCircle {
      var circleRenderer = MKCircleRenderer(overlay: overlay)
      circleRenderer.lineWidth = 1.0
      circleRenderer.strokeColor = UIColor.purpleColor()
      circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
      return circleRenderer
    }
    return nil
  }

  func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
    // Delete geotification
    var geotification = view.annotation as! Geotification
    removeGeotification(geotification)
    saveAllGeotifications()
  }

  // MARK: Map overlay functions

  func addRadiusOverlayForGeotification(geotification: Geotification) {
    mapView?.addOverlay(MKCircle(centerCoordinate: geotification.coordinate, radius: geotification.radius))
  }

  func removeRadiusOverlayForGeotification(geotification: Geotification) {
    // Find exactly one overlay which has the same coordinates & radius to remove
    if let overlays = mapView?.overlays {
      for overlay in overlays {
        if let circleOverlay = overlay as? MKCircle {
          var coord = circleOverlay.coordinate
          if coord.latitude == geotification.coordinate.latitude && coord.longitude == geotification.coordinate.longitude && circleOverlay.radius == geotification.radius {
            mapView?.removeOverlay(circleOverlay)
            break
          }
        }
      }
    }
  }

  // MARK: Other mapview functions

  @IBAction func zoomToCurrentLocation(sender: AnyObject) {
    zoomToUserLocationInMapView(mapView)
  }
}
