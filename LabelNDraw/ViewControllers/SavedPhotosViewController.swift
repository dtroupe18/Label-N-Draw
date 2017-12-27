//
//  SavedPhotosViewController.swift
//  SnapChatCamera
//
//  Created by Dave on 12/20/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit
import CoreData

class SavedPhotosViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var imageToPass: UIImage?
    var savedPhotos = [SavedImage]()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let fileManager = FileManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        // cell.indexPath = indexPath
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.black.cgColor
        cell.imageView.image = savedPhotos[indexPath.row].image
        
        cell.deleteTapAction = { (ImageCell) in
            self.askToConfirmDelete(indexPath: indexPath)
        }
        return cell
    }
    
    private func askToConfirmDelete(indexPath: IndexPath) {
        let confirmAlert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete this image?", preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            // call function to delete
            self.deleteImage(imageName: self.savedPhotos[indexPath.row].relativePath, index: indexPath.row)
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            // do nothing
        }))
        
        self.present(confirmAlert, animated: true, completion: nil)
    }
    
    private func deleteImage(imageName: String, index: Int) {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsURL.appendingPathComponent(imageName)
        
        if fileManager.fileExists(atPath: fullPath.absoluteURL.path) {
            do {
                try fileManager.removeItem(at: fullPath)
                self.savedPhotos.remove(at: index)
                self.collectionView.reloadData()
            }
            catch {
                let deleteFailedAlert = UIAlertController(title: "Unable to Delete Photo", message: "Please try again.", preferredStyle: .alert)
                
                let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                // relate actions to controllers
                deleteFailedAlert.addAction(ok)
                present(deleteFailedAlert, animated: true, completion: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.imageToPass = self.savedPhotos[indexPath.row].image
            self.performSegue(withIdentifier: "toAnnotateFromSavedPhotos", sender: nil)
        }
    }
    
    func fetchFromCoreData() {
        let container = appDelegate.persistentContainer
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<Image>(entityName: "Image")
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let images = try context.fetch(fetchRequest)
            for image in images {
                if let relativePath = image.filePath {
                    let filePath = documentsURL.appendingPathComponent(relativePath)
                    if FileManager.default.fileExists(atPath: filePath.path) {
                        if let contentsOfFilePath = UIImage(contentsOfFile: filePath.path) {
                            let upImage = contentsOfFilePath.correctlyOrientedImage()
                            savedPhotos.append(SavedImage(relativePath: relativePath, image: upImage))
                        }
                    }
                }
            }
        }
        catch {
            print("error retrieving images from core data")
        }
        collectionView.reloadData()
    }
    
    private func initialize() {
        // CollectionView setup
        collectionView.delegate = self
        collectionView.dataSource = self
        let flow = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        let width = UIScreen.main.bounds.size.width
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            flow.itemSize = CGSize(width: width / 2.0, height: width / 2.0)
        case .pad:
            flow.itemSize = CGSize(width: width / 3.0, height: width / 3.0)
        case .unspecified:
            flow.itemSize = CGSize(width: width / 2.0, height: width / 2.0)
        default:
            flow.itemSize = CGSize(width: width / 2.0, height: width / 2.0)
        }
        fetchFromCoreData()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "backToCamera", sender: nil)
        }
    }
    
    //MARKER: IMPORT A PHOTO
    @IBAction func addPressed(_ sender: Any) {
        // show photo library and import an image
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.modalPresentationStyle = .fullScreen
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // save to disk and core data
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let rotatedImage = image.correctlyOrientedImage()
            if let pngImageData = UIImagePNGRepresentation(rotatedImage) {
                let time = Date().millisecondsSince1970
                let fileName = String("\(time).png")
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fullPath = documentsURL.appendingPathComponent(fileName)
                
                if fileManager.fileExists(atPath: fullPath.path) {
                    // this should never happen
                    picker.dismiss(animated: true, completion: nil)
                    showAlertMessage(title: "Error", message: "Unable to save image. Please try again.")
                }
                else {
                    do {
                        try pngImageData.write(to: fullPath, options: .atomic)
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let containter = appDelegate.persistentContainer
                        let context = containter.viewContext
                        let entity = Image(context: context)
                        entity.filePath = fileName
                        appDelegate.saveContext()
                        savedPhotos.append(SavedImage(relativePath: fileName, image: image))
                        collectionView.reloadData()
                        picker.dismiss(animated: true, completion: nil)
                    }
                    catch {
                        picker.dismiss(animated: true, completion: nil)
                        showAlertMessage(title: "Error", message: "Unable to save image to disk. Please try again.")
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func showAlertMessage(title: String, message: String) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(defaultAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAnnotateFromSavedPhotos" {
            if let destination = segue.destination as? AnnotateViewController {
                if imageToPass != nil {
                    destination.originalImage = imageToPass
                }
            }
        }
    }
}
