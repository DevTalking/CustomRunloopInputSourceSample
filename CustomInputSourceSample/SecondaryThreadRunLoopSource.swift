//
//  SecondaryThreadRunLoopSource.swift
//  CustomInputSourceSample
//
//  Created by JaceFu on 16/1/13.
//  Copyright © 2016年 DevTalking. All rights reserved.
//

import UIKit

class SecondaryThreadRunLoopSource: NSObject {

    var runloopSource: CFRunLoopSourceRef?
    var commandBuffer: Array<MainThreadRunLoopSourceContext>?
    
    override init() {
        
        super.init()
        
        var runloopSourceContext = CFRunLoopSourceContext(version: 0, info: unsafeBitCast(self, UnsafeMutablePointer<Void>.self), retain: nil, release: nil, copyDescription: nil, equal: nil, hash: nil, schedule: runloopSourceScheduleRoutine(), cancel: runloopSourceCancelRoutine(), perform: runloopSourcePerformRoutine())
        
        runloopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &runloopSourceContext)
        
        commandBuffer = Array<MainThreadRunLoopSourceContext>()
        
    }
    
    func addToCurrentRunLoop() {
        
        let cfrunloop = CFRunLoopGetCurrent()
        
        if let rls = runloopSource {
            
            CFRunLoopAddSource(cfrunloop, rls, kCFRunLoopDefaultMode)
            
        }

    }
    
    func signalSourceAndWakeUpRunloop(runloop: CFRunLoopRef) {
        
        CFRunLoopSourceSignal(runloopSource)
        
        CFRunLoopWakeUp(runloop)
        
    }
    
    func runloopSourcePerformRoutine() -> @convention(c) (UnsafeMutablePointer<Void>) -> Void {
        
        return { info -> Void in
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            appDelegate.performSelector("performSecondaryThreadRunLoopSourceTask")
            
        }
        
    }
    
    func runloopSourceScheduleRoutine() -> @convention(c) (UnsafeMutablePointer<Void>, CFRunLoop!, CFString!) -> Void {
        
        return { (info, runloop, runloopMode) -> Void in
            
            let secondaryThreadRunloopSource = unsafeBitCast(info, SecondaryThreadRunLoopSource.self)
            
            let secondaryThreadRunloopSourceContext = SecondaryThreadRunLoopSourceContext(runloop: runloop, runloopSource: secondaryThreadRunloopSource)
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            appDelegate.performSelectorOnMainThread("registerSecondaryThreadRunLoopSource:", withObject: secondaryThreadRunloopSourceContext, waitUntilDone: true)
            
        }
        
    }
    
    func runloopSourceCancelRoutine() -> @convention(c) (UnsafeMutablePointer<Void>, CFRunLoop!, CFString!) -> Void {
        
        return { (info, runloop, runloopMode) -> Void in
            
            let secondaryThreadRunloopSource = unsafeBitCast(info, SecondaryThreadRunLoopSource.self)
            
            CFRunLoopSourceInvalidate(secondaryThreadRunloopSource.runloopSource)
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            appDelegate.performSelector("removeSecondaryThreadRunloopSourceContext")
            
        }
        
    }
    
}
