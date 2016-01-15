//
//  SecondaryThreadRunLoopSourceContext.swift
//  CustomInputSourceSample
//
//  Created by JaceFu on 16/1/13.
//  Copyright © 2016年 DevTalking. All rights reserved.
//

import Foundation

class SecondaryThreadRunLoopSourceContext: NSObject {
    
    var runloop: CFRunLoopRef?
    var runloopSource: SecondaryThreadRunLoopSource?
    
    init(runloop: CFRunLoopRef, runloopSource: SecondaryThreadRunLoopSource) {
        
        self.runloop = runloop
        self.runloopSource = runloopSource
        
    }
    
}