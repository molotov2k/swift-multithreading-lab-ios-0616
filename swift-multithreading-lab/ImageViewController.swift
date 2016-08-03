//
//  ImageViewController.swift
//  swift-multithreading-lab
//
//  Created by Flatiron School on 7/28/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import Foundation
import UIKit
import CoreImage

class ImageViewController : UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var antiqueButton: UIBarButtonItem!
    var scrollView: UIScrollView!
    var imageView: UIImageView!
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    @IBAction func antiqueButtonTapped(sender: AnyObject) {
        startAcitivityIndecator()
        antiqueButton.enabled = false
        antiqueButton.title = "Rendering"
        
        let filterOperation = NSBlockOperation {
            self.filterImage({ (success) in
                NSOperationQueue.mainQueue().addOperationWithBlock({ 
                    self.stopActivityIndecator()
                    self.antiqueButton.enabled = true
                    self.antiqueButton.title = "Antique"
                })
                success ? print("Image filtering complete") : print("Image filtering did not complete")
            })
        }
        
        filterOperation.qualityOfService = .UserInitiated
        NSOperationQueue().addOperation(filterOperation)
        
    }
    
    
    func filterImage(completion: (Bool) -> ()) {
        guard let image = imageView?.image, cgimg = image.CGImage else {
            print("imageView doesn't have an image!")
            return
        }
        
        let openGLContext = EAGLContext(API: .OpenGLES2)
        let context = CIContext(EAGLContext: openGLContext!)
        let coreImage = CIImage(CGImage: cgimg)
        
        let sepiaFilter = CIFilter(name: "CISepiaTone")
        sepiaFilter?.setValue(coreImage, forKey: kCIInputImageKey)
        sepiaFilter?.setValue(1, forKey: kCIInputIntensityKey)
        print("Applying CISepiaTone")
        
        if let sepiaOutput = sepiaFilter?.valueForKey(kCIOutputImageKey) as? CIImage {
            let exposureFilter = CIFilter(name: "CIExposureAdjust")
            exposureFilter?.setValue(sepiaOutput, forKey: kCIInputImageKey)
            exposureFilter?.setValue(1, forKey: kCIInputEVKey)
            print("Applying CIExposureAdjust")
            
            if let exposureOutput = exposureFilter?.valueForKey(kCIOutputImageKey) as? CIImage {
                let output = context.createCGImage(exposureOutput, fromRect: exposureOutput.extent)
                let result = UIImage(CGImage: output)
                
                print("Rendering image")
                
                UIGraphicsBeginImageContextWithOptions(result.size, false, result.scale)
                result.drawAtPoint(CGPointZero)
                let finalResult = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                print("Setting final result")
                NSOperationQueue.mainQueue().addOperationWithBlock({ 
                    self.imageView?.image = finalResult
                })
                completion(true)
            }
        }
    }
}

extension ImageViewController {
    
    func setupViews() {
        imageView = UIImageView(image: UIImage(named: "FlatironFam"))
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.backgroundColor = UIColor.blackColor()
        scrollView.contentSize = imageView.bounds.size
        scrollView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        scrollView.contentOffset = CGPoint(x: 800, y: 200)
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        scrollView.delegate = self
        
        setZoomScale()
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.color = UIColor.cyanColor()
        activityIndicator.center = view.center
        
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    override func viewWillLayoutSubviews() {
        setZoomScale()
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }
    
    func setZoomScale() {
        let imageViewSize = imageView.bounds.size
        let scrollViewSize = scrollView.bounds.size
        let widthScale = scrollViewSize.width / imageViewSize.width
        let heightScale = scrollViewSize.height / imageViewSize.height
        
        scrollView.minimumZoomScale = min(widthScale, heightScale)
        scrollView.zoomScale = 1.0
    }
    
    func startAcitivityIndecator() {
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func stopActivityIndecator() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    
}
