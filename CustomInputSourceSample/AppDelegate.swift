//
//  AppDelegate.swift
//  CustomInputSourceSample
//
//  Created by JaceFu on 16/1/12.
//  Copyright © 2016年 DevTalking. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var mainThreadRunloopSourceContext: MainThreadRunLoopSourceContext?
    var secondaryThreadRunloopSourceContext: SecondaryThreadRunLoopSourceContext?
    var mainCollectionViewController: MainCollectionViewController?
    
    func registerMainThreadRunLoopSource(runloopSourceContext: MainThreadRunLoopSourceContext) {
        
        mainThreadRunloopSourceContext = runloopSourceContext
        
    }
    
    func registerSecondaryThreadRunLoopSource(runloopSourceContext: SecondaryThreadRunLoopSourceContext) {
        
        secondaryThreadRunloopSourceContext = runloopSourceContext
        
        sendCommandToSecondaryThread()
        
    }
    
    func sendCommandToSecondaryThread() {
        
        secondaryThreadRunloopSourceContext?.runloopSource?.commandBuffer?.append(mainThreadRunloopSourceContext!)
        
        secondaryThreadRunloopSourceContext?.runloopSource?.signalSourceAndWakeUpRunloop(secondaryThreadRunloopSourceContext!.runloop!)
        
    }
    
    func performMainThreadRunLoopSourceTask() {
        
        if mainThreadRunloopSourceContext!.runloopSource!.commandBuffer!.count > 0 {
        
            mainThreadRunloopSourceContext!.runloopSource!.commandBuffer!.removeAll()
            
            mainCollectionViewController!.collectionView.reloadData()
            
            let timer = NSTimer(timeInterval: 1, target: self, selector: "sendCommandToSecondaryThread", userInfo: nil, repeats: false)
            
            NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
        
        }
        
    }
    
    func performSecondaryThreadRunLoopSourceTask() {
        
        if secondaryThreadRunloopSourceContext!.runloopSource!.commandBuffer!.count > 0 {
            
            mainCollectionViewController!.generateRandomAlpha()
            
            let mainThreadRunloopSourceContext = secondaryThreadRunloopSourceContext!.runloopSource!.commandBuffer![0]
            
            secondaryThreadRunloopSourceContext!.runloopSource!.commandBuffer!.removeAll()
            
            mainThreadRunloopSourceContext.runloopSource?.commandBuffer?.append(secondaryThreadRunloopSourceContext!)
            
            mainThreadRunloopSourceContext.runloopSource?.signalSourceAndWakeUpRunloop(mainThreadRunloopSourceContext.runloop!)
            
        }
        
    }
    
    func removeMainThreadRunloopSourceContext() {
        
        mainThreadRunloopSourceContext = nil
        
    }
    
    func removeSecondaryThreadRunloopSourceContext() {
        
        secondaryThreadRunloopSourceContext = nil
        
    }

}

