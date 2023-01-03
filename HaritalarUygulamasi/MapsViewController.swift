//
//  ViewController.swift
//  HaritalarUygulamasi
//
//  Created by Semih Mac on 25.12.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData


class MapsViewController: UIViewController, MKMapViewDelegate,CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
 
    @IBOutlet weak var descriptionTxt: UITextField!
    @IBOutlet weak var titleTxt: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var selectedLat = Double()
    var selectedLong = Double()
    
    var selectedName = ""
    var selectedId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longClick(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedName != "" {
            if let uuidString = selectedId?.uuidString {
                let appdelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appdelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
                fetchRequest.returnsObjectsAsFaults = false
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                do{
                    let results = try context.fetch(fetchRequest)
                    if results.count > 0 {
                        let result = results[0] as! NSManagedObject
                        
                        if let name = result.value(forKey: "name") as? String {
                            titleTxt.text = name
                        }
                        if let desc = result.value(forKey: "desc") as? String {
                            descriptionTxt.text = desc
                        }
                        if let lat = result.value(forKey: "lat") as? Double {
                            selectedLat = lat
                        }
                        if let long = result.value(forKey: "long") as? Double {
                           selectedLong = long
                        }
                        
                        let anotation = MKPointAnnotation()
                        let coordinate = CLLocationCoordinate2D(latitude: selectedLat, longitude: selectedLong)
                        anotation.coordinate = coordinate
                        if let title = titleTxt.text as String? {
                            anotation.title=title
                        }
                        if let description = descriptionTxt.text as String? {
                            anotation.subtitle=description
                        }
                        
                        mapView.addAnnotation(anotation)
                        locationManager.stopUpdatingLocation()
                        
                        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        let region = MKCoordinateRegion(center: coordinate, span: span)
                        mapView.setRegion(region, animated: true)
                    }
                }
                catch{
                    print("Hata")
                }
            }
        }
        else
        {
            
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedName == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
       
    }
    @objc func longClick(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            selectedLat = coordinate.latitude
            selectedLong = coordinate.longitude
            
            let anotation = MKPointAnnotation()
            anotation.coordinate=coordinate
            if let title = titleTxt.text as String? {
                anotation.title=title
            }
            if let description = descriptionTxt.text as String? {
                anotation.subtitle=description
            }
            
            mapView.addAnnotation(anotation)
        }
       
        
    }
    
    @IBAction func save(_ sender: Any) {
        
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appdelegate.persistentContainer.viewContext
        let location = NSEntityDescription.insertNewObject(forEntityName: "Locations", into: context)
        location.setValue(UUID(), forKey: "id")
        location.setValue(titleTxt.text, forKey: "name")
        location.setValue(descriptionTxt.text, forKey: "desc")
        location.setValue(selectedLat, forKey: "lat")
        location.setValue(selectedLong, forKey: "long")
        
        
        do{
            try context.save()
            print("Kayıt Edildi")
        }catch{
            print("Hata")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newLocationAdded"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let annoId = "myAnnotation"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: annoId)
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: annoId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let btn = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = btn
        }
        else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != "" {
            let requestLocation = CLLocation(latitude: selectedLat, longitude: selectedLong)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarkArray, error in
                if let  placemarks = placemarkArray {
                    if placemarks.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.selectedName
                        let launchopt = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchopt)
                    }
                }
            }
        }
    }
}

