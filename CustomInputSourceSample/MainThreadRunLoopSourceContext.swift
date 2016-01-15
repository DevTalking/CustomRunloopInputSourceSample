//
//  MainThreadRunLoopSourceContext.swift
//  CustomInputSourceSample
//
//  Created by JaceFu on 16/1/14.
//  Copyright © 2016年 DevTalking. All rights reserved.
//

import Foundation

class MainThreadRunLoopSourceContext: NSObject {
    
    var runloop: CFRunLoopRef?
    var runloopSource: MainThreadRunLoopSource?
    
    init(runloop: CFRunLoopRef, runloopSource: MainThreadRunLoopSource) {
        
        self.runloop = runloop
        self.runloopSource = runloopSource
        
    }
    
}