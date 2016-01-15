//
//  MainThreadRunLoopSource.swift
//  CustomInputSourceSample
//
//  Created by JaceFu on 16/1/13.
//  Copyright © 2016年 DevTalking. All rights reserved.
//

import UIKit

class MainThreadRunLoopSource: NSObject {

    var runloopSource: CFRunLoopSourceRef?
    var commandBuffer: Array<SecondaryThreadRunLoopSourceContext>?
    
    override init() {
        
        super.init()
        
        var runloopSourceContext = CFRunLoopSourceContext(version: 0, info: unsafeBitCast(self, UnsafeMutablePointer<Void>.self), retain: nil, release: nil, copyDescription: nil, equal: nil, hash: nil, schedule: runloopSourceScheduleRoutine(), cancel: runloopSourceCancelRoutine(), perform: runloopSourcePerformRoutine())
        
        runloopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &runloopSourceContext)
        
        commandBuffer = Array<SecondaryThreadRunLoopSourceContext>()
        
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
            
            appDelegate.performSelector("performMainThreadRunLoopSourceTask")
        
        }
        
    }
    
    func runloopSourceScheduleRoutine() -> @convention(c) (UnsafeMutablePointer<Void>, CFRunLoop!, CFString!) -> Void {
        
        return { (info, runloop, runloopMode) -> Void in
        
            let mainThreadRunloopSource = unsafeBitCast(info, MainThreadRunLoopSource.self)
            
            let mainThreadRunloopSourceContext = MainThreadRunLoopSourceContext(runloop: runloop, runloopSource: mainThreadRunloopSource)
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            appDelegate.performSelector("registerMainThreadRunLoopSource:", withObject: mainThreadRunloopSourceContext)
        
        }
        
    }
    
    func runloopSourceCancelRoutine() -> @convention(c) (UnsafeMutablePointer<Void>, CFRunLoop!, CFString!) -> Void {
        
        return { (info, runloop, runloopMode) -> Void in
            
            let mainThreadRunloopSource = unsafeBitCast(info, MainThreadRunLoopSource.self)
            
            CFRunLoopSourceInvalidate(mainThreadRunloopSource.runloopSource)
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            appDelegate.performSelector("performMainThreadRunLoopSourceTask")
            
        }
        
    }
    
}
