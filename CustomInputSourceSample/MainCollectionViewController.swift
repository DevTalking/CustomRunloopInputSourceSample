//
//  MainCollectionViewController.swift
//  CustomInputSourceSample
//
//  Created by JaceFu on 16/1/12.
//  Copyright © 2016年 DevTalking. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class MainCollectionViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let numberOfCell = 32
    var alphaArray = Array<CGFloat>()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        collectionView.dataSource = self
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        appDelegate.mainCollectionViewController = self

    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
    }

    @IBAction func start(sender: AnyObject) {
        
        let mainThreadRunLoopSource = MainThreadRunLoopSource()
        
        mainThreadRunLoopSource.addToCurrentRunLoop()
        
        let secondaryThread = NSThread(target: self, selector: "startThreadWithRunloop", object: nil)
        
        secondaryThread.start()
        
    }
    
    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
        
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return numberOfCell
        
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
        
        cell.alpha = alphaArray.count != 0 ? alphaArray[indexPath.row] : 1
    
        return cell
        
    }
    
    // MARK: Run in the secondary thread
    
    func startThreadWithRunloop() {
        
        autoreleasepool{
            
            var done = false
            
            let secondaryThreadRunLoopSource = SecondaryThreadRunLoopSource()
            
            secondaryThreadRunLoopSource.addToCurrentRunLoop()
            
            repeat {
                
                let result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 5, true)
                
                if ((result == CFRunLoopRunResult.Stopped) || (result == CFRunLoopRunResult.Finished)) {
                    
                    done = true;
                    
                }
                
            } while(!done)
            
        }
        
    }

    func generateRandomAlpha() {
        
        alphaArray.removeAll()
        
        for var index = 0; index < numberOfCell; index++ {
            
            let transparence = randomInRange(0...100)
            
            alphaArray.append(CGFloat(transparence) * 0.01)

        }
        
    }
    
    func randomInRange(range: Range<Int>) -> Int {
        
        let count  = UInt32(range.endIndex - range.startIndex)
        
        return Int(arc4random_uniform(count)) + range.startIndex
        
    }

}
