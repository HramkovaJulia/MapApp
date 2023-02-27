//
//  ViewController.swift
//  MapApp
//
//  Created by Artyom Prima on 20.02.2023.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {
    
    private var locations: [NSManagedObject] = []
    private let annotation = MKPointAnnotation()
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var selectedLocationIndex = 0
    
    private let buttonTurnUpRight: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(navigateTurnUpRight), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.setImage(UIImage(systemName: "arrowshape.turn.up.right"), for: .normal)
        return button
    }()
    
    private let buttonTurnUpLeft: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(navigateTurnUpLeft), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.setImage(UIImage(systemName: "arrowshape.turn.up.left"), for: .normal)
        return button
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(TableViewCell.self, forCellReuseIdentifier: TableViewCell.identifier)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navSettings()
        setConstraints()
        tableView.isHidden = true
        segmentedControl.selectedSegmentIndex = 0
        let unselectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        segmentedControl.setTitleTextAttributes(unselectedTextAttributes, for: .normal)
        
        let initialLocation = CLLocation(latitude: 43.2567, longitude: 76.9286)
        let regionRadius: CLLocationDistance = 1000
        
        let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        longPressRecognizer.delegate = self
        mapView.addGestureRecognizer(longPressRecognizer)
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGestureRecognizer.direction = .right
        tableView.addGestureRecognizer(swipeGestureRecognizer)
        
        // Set up the map view
        mapView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        loadLocations()
    }
    
    @objc func handleSwipe() {
        tableView.isHidden = true
    }
    
    func navSettings(){
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(tableViewTapped))
        self.navigationItem.rightBarButtonItem?.tintColor = .white
    }
    
    @objc func tableViewTapped(){
        tableView.isHidden = false
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = 0.9
        blurView.backgroundColor = UIColor.clear
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView = blurView
    }
    
    @objc func navigateTurnUpRight(){
        selectedLocationIndex += 1
        if selectedLocationIndex >= mapView.annotations.count {
            selectedLocationIndex = 0
        }
        let nextAnnotation = mapView.annotations[selectedLocationIndex]
        let region = MKCoordinateRegion(center: nextAnnotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }
    
    @objc func navigateTurnUpLeft() {
        selectedLocationIndex -= 1
        if selectedLocationIndex < 0 {
            selectedLocationIndex = mapView.annotations.count - 1
        }
        let previousAnnotation = mapView.annotations[selectedLocationIndex]
        mapView.setCenter(previousAnnotation.coordinate, animated: true)
    }

    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        if gestureRecognizer.state == .ended {
            let alert = UIAlertController(title: "Add place", message: "Fill all the fields", preferredStyle: .alert)
            alert.addTextField { (textField:UITextField) in
                textField.placeholder = "Enter title"
            }
            alert.addTextField { (textField:UITextField) in
                textField.placeholder = "Enter Subtitle"
            }
            alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [self] (action:UIAlertAction) in
                guard let textField = alert.textFields?.first else {
                    return
                }
                guard let textField2 = alert.textFields?[1] else {
                    return
                }
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = textField.text
                annotation.subtitle = textField2.text
                mapView.addAnnotation(annotation)
                let latitude = coordinate.latitude
                let longitude = coordinate.longitude
                saveLocation(textField.text!, textField2.text!, latitude, longitude)
                annotation.title = textField.text
                annotation.subtitle = textField2.text
                self.mapView.addAnnotation(annotation)
                self.tableView.reloadData()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.overrideUserInterfaceStyle = .dark
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    func setConstraints(){
        view.addSubview(mapView)
        view.addSubview(tableView)
        view.addSubview(segmentedControl)
        view.addSubview(buttonTurnUpRight)
        view.addSubview(buttonTurnUpLeft)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            segmentedControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -26),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            buttonTurnUpRight.leadingAnchor.constraint(equalTo: segmentedControl.trailingAnchor, constant: 6),
            buttonTurnUpRight.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            
            buttonTurnUpLeft.trailingAnchor.constraint(equalTo: segmentedControl.leadingAnchor, constant: -6),
            buttonTurnUpLeft.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
        ])
    }
    
    private let segmentedControl: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["Standard", "Hybrid", "Satillete"])
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.selectedSegmentTintColor = .black
        segment.addTarget(self, action: #selector(changeStilyMapView(_:)), for: .valueChanged)
        
        return segment
    }()
    
    @objc func changeStilyMapView(_ segmentedControl: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0 :
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .hybrid
        case 2:
            mapView.mapType = .satellite
        default:
            print("Something Wrong")
        }
    }
    
    func loadLocations(){
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LocationModel")
        do {
            locations = try context.fetch(fetchRequest)
            
            for location in locations {
                let title = location.value(forKey: "nameLocation") as! String
                let subtitle = location.value(forKey: "descriptionLocation") as! String
                let latitude = location.value(forKey: "latitude") as! Double
                let longitude = location.value(forKey: "longitude") as! Double
                
                let annotation = MKPointAnnotation()
                annotation.title = title
                annotation.subtitle = subtitle
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                mapView.addAnnotation(annotation)
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    //добавить локацию в CoreData
    func saveLocation(_ name: String, _ description: String, _ latitude: Double, _ longitude: Double){
        let entity = NSEntityDescription.entity(forEntityName: "LocationModel", in: context)!
        let location = NSManagedObject(entity: entity, insertInto: context)
        location.setValue(name, forKeyPath: "nameLocation")
        location.setValue(description, forKeyPath: "descriptionLocation")
        location.setValue(latitude, forKeyPath: "latitude")
        location.setValue(longitude, forKeyPath: "longitude")
        do {
            try context.save()
            locations.append(location)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        if let locationAnnotation = annotation as? MKPointAnnotation {
            let fetchRequest: NSFetchRequest<LocationModel> = LocationModel.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "latitude == %lf AND longitude == %lf", annotation.coordinate.latitude, annotation.coordinate.longitude)
            do {
                let locations = try context.fetch(fetchRequest)
                guard let location = locations.first else {
                    return
                }
                let alertController = UIAlertController(title: "Edit Location", message: "Edit or delete the selected location", preferredStyle: .alert)
                alertController.addTextField { textField in
                    textField.placeholder = "Location name"
                    textField.text = location.nameLocation // Set the current location name as the default text
                }
                alertController.addTextField { textField in
                    textField.placeholder = "Location notes"
                    textField.text = location.descriptionLocation // Set the current location notes as the default text
                }
                let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    guard let nameTextField = alertController.textFields?.first, let notesTextField = alertController.textFields?.last else { return }
                    location.nameLocation = nameTextField.text
                    location.descriptionLocation = notesTextField.text
                    do {
                        try self.context.save()
                        mapView.removeAnnotation(annotation)
//                        mapView.addAnnotation(locationAnnotation)
                        self.loadLocations()
                        //reloadRows
                        self.tableView.reloadData()
                    } catch {
                        print("Failed to update location: \(error)")
                    }
                }
                let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                    guard let self = self else { return }
                    self.context.delete(location)
                    do {
                        try self.context.save()
                        mapView.removeAnnotation(annotation)
                        if let index = self.locations.firstIndex(where: {$0 == location}) {
                            self.locations.remove(at: index)
                        }
                        //reloadRows
                        self.tableView.reloadData()
                    } catch {
                        print("Failed to delete location: \(error)")
                    }
                }
                alertController.addAction(saveAction)
                alertController.addAction(deleteAction)
                present(alertController, animated: true, completion: nil)
            } catch {
                print("Failed to fetch location: \(error)")
            }
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        locations.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Удаляем локацию из CoreData
            let location = locations[indexPath.row]
            context.delete(location)
            do {
                try context.save()
                locations.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                mapView.removeAnnotations(mapView.annotations)
                loadLocations()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.identifier, for: indexPath) as! TableViewCell
        let location = locations[indexPath.row]
        cell.titleLabel.text = location.value(forKeyPath: "nameLocation") as? String
        cell.descriptionLabel.text = location.value(forKeyPath: "descriptionLocation") as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let locations = try? context.fetch(LocationModel.fetchRequest()) as? [LocationModel] else {
            return
        }
        let location = locations[indexPath.row]
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        tableView.isHidden = true
        mapView.setCenter(annotation.coordinate, animated: true)
        mapView.selectAnnotation(annotation, animated: true)
        
    }
}




