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
    
    private var point: CGPoint?
    private var locationName: String?
    
    var locations: [NSManagedObject] = []
    
    private let buttonTurnUpRight: UIButton = {
        let button = UIButton()
//        button.addTarget(self, action: #selector(navigateTurnUpRight), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.setImage(UIImage(systemName: "arrowshape.turn.up.right"), for: .normal)
        return button
    }()
    
    private let buttonTurnUpLeft: UIButton = {
        let button = UIButton()
//        button.addTarget(self, action: #selector(navigateTurnUpLeft), for: .touchUpInside)
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
        
        // Set up the map view
        mapView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        loadLocations()
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
    
//    @objc func navigateTurnUpRight(){
//        guard let annotations = mapView.annotations as? [MKAnnotation], !annotations.isEmpty else {
//            return
//        }
//        if let currentSelection = mapView.selectedAnnotations.first,
//           let currentIndex = annotations.firstIndex(where: { $0 === currentSelection }),
//           currentIndex < annotations.count - 1 {
//            let nextIndex = currentIndex + 1
//            let nextAnnotation = annotations[nextIndex]
//
//            mapView.selectAnnotation(nextAnnotation, animated: true)
//            mapView.setCenter(nextAnnotation.coordinate, animated: true)
//
//        } else {
//            mapView.selectAnnotation(annotations.first!, animated: true)
//            mapView.setCenter(annotations.first!.coordinate, animated: true)
//        }
//    }
    
//    @objc func navigateTurnUpLeft() {
//        guard let annotations = mapView.annotations as? [MKAnnotation], !annotations.isEmpty else {
//            return
//        }
//        
//        if let currentSelection = mapView.selectedAnnotations.first,
//           let currentIndex = annotations.firstIndex(where: { $0 === currentSelection }),
//           currentIndex > 0 {
//            let previousIndex = currentIndex - 1
//            let previousAnnotation = annotations[previousIndex]
//            mapView.selectAnnotation(previousAnnotation, animated: true)
//            mapView.setCenter(previousAnnotation.coordinate, animated: true)
//        } else {
//            mapView.selectAnnotation(annotations.last!, animated: true)
//            mapView.setCenter(annotations.last!.coordinate, animated: true)
//        }
//    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        point = gestureRecognizer.location(in: mapView)
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
                locationName = textField.text
                self.title = locationName
                guard let textField2 = alert.textFields?[1] else {
                    return
                }
                if let subtitle = textField2.text {
                    let annotation = MKPointAnnotation()
                    let coordinate = mapView.convert(point!, toCoordinateFrom: mapView)
                    annotation.coordinate = coordinate
                    annotation.title = locationName
                    annotation.subtitle = subtitle
                    mapView.addAnnotation(annotation)
                    let latitude = coordinate.latitude
                    let longitude = coordinate.longitude
                    saveLocation(locationName!, subtitle, latitude, longitude)
                }
                
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
//        view.addSubview(tableView)
        view.addSubview(segmentedControl)
//        view.addSubview(buttonTurnUpRight)
//        view.addSubview(buttonTurnUpLeft)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
//            tableView.topAnchor.constraint(equalTo: view.topAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
            segmentedControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -26),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            
//            buttonTurnUpRight.leadingAnchor.constraint(equalTo: segmentedControl.trailingAnchor, constant: 6),
//            buttonTurnUpRight.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
//            
//            buttonTurnUpLeft.trailingAnchor.constraint(equalTo: segmentedControl.leadingAnchor, constant: -6),
//            buttonTurnUpLeft.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
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
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LocationModel")
        do {
            locations = try context.fetch(fetchRequest)
            
            for location in locations {
                let title = location.value(forKey: "nameLocation") as! String
                let subtitle = location.value(forKey: "descriptionLocation") as! String
                let latitude = location.value(forKey: "latitude") as! Double
                let longitude = location.value(forKey: "longitude") as! Double
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//                guard let latitude = location.value(forKey: "latitude") as? Double, let longitude = location.value(forKey: "longitude") as? Double else {
//                    continue
//                }
                let annotation = MKPointAnnotation()
                               annotation.title = title
                               annotation.subtitle = subtitle
                               annotation.coordinate = coordinate
                               mapView.addAnnotation(annotation)
                
//                let annotation = MKPointAnnotation()
//                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//                mapView.addAnnotation(annotation)
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    //добавить локацию в CoreData
    func saveLocation(_ name: String, _ description: String, _ latitude: Double, _ longitude: Double ){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "LocationModel", in: managedContext)!
        let location = NSManagedObject(entity: entity, insertInto: managedContext)
        location.setValue(name, forKeyPath: "nameLocation")
        location.setValue(description, forKeyPath: "descriptionLocation")
        
        location.setValue(latitude, forKeyPath: "latitude")
        location.setValue(longitude, forKeyPath: "longitude")
        
        do {
            try managedContext.save()
            locations.append(location)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.identifier, for: indexPath) as! TableViewCell
        let location = locations[indexPath.row]
        cell.titleLabel.text = location.value(forKeyPath: "nameLocation") as? String
        cell.descriptionLabel.text = location.value(forKeyPath: "descriptionLocation") as? String
        return cell
    }
}



