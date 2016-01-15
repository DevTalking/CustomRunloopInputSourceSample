## 自定义Run Loop事件源的实际运用
我们先看看示例Demo的效果：

![LearnThread-5](http://7xpp8a.com1.z0.glb.clouddn.com/LearnThread-5.gif)

在这个示例中，创建了两个自定义事件源，一个添加到主线程中，另一个添加到二级线程中。主线程给二级线程中的自定义事件源发送事件消息，目的是让其改变所有`UICollectionViewCell`的透明度，当二级线程收到事件消息后执行计算每个`UICollectionViewCell`透明度的任务，然后再给主线程的自定义事件源发送事件消息，让其更新`UICollectionViewCell`的透明度并显示。下面来看看类图：

![LearnThread-6](http://7xpp8a.com1.z0.glb.clouddn.com/LearnThread-6-new.png)

整个工程一共就这六个类：
- `MainCollectionViewController`：程序主控制器，启动程序、展示UI及计算`UICollectionViewCell`透明度的相关方法。
- `MainThreadRunLoopSource`：主线程自定义事件源管理对象，负责初始化事件源，将事件源添加至指定线程，标记事件源并唤醒指定Run Loop以及包含上文中说过的事件源最主要的三个回调方法。
- `MainThreadRunLoopSourceContext`：主线程自定义事件源上下文，可获取到对应的事件源及添加了该事件源的Run Loop。
- `SecondaryThreadRunLoopSource`：二级线程自定义事件源管理对象，负责初始化事件源，将事件源添加至指定线程，标记事件源并唤醒指定Run Loop以及包含上文中说过的事件源最主要的三个回调方法。
- `SecondaryThreadRunLoopSourceContext`：二级线程自定义事件源上下文，可获取到对应的事件源及添加了该事件源的Run Loop。
- `AppDelegate`：应用程序代理类，这里零时充当为各自定义事件源回调方法执行内容的管理类。

下面我按照程序的运行顺序一一对这些类及属性和方法进行简单说明。

### 程序开始运行
`MainCollectionViewController`类中与UI展示相关的方法在这里就不再累赘了。点击**Start**按钮，调用`start()`方法，初始化`MainThreadRunLoopSource`对象，在这个过程中初始化了`CFRunLoopSourceContext`对象并且创建`CFRunLoopSource`对象以及初始化该事件源的指令池：

```swift
let mainThreadRunLoopSource = MainThreadRunLoopSource()
        
mainThreadRunLoopSource.addToCurrentRunLoop()
```

```swift
var runloopSourceContext = CFRunLoopSourceContext(version: 0, info: unsafeBitCast(self, UnsafeMutablePointer<Void>.self), retain: nil, release: nil, copyDescription: nil, equal: nil, hash: nil, schedule: runloopSourceScheduleRoutine(), cancel: runloopSourceCancelRoutine(), perform: runloopSourcePerformRoutine())
        
runloopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &runloopSourceContext)
        
commandBuffer = Array<SecondaryThreadRunLoopSourceContext>()
```

这里需要注意的是`CFRunLoopSourceContext`的`init`方法中的第二个参数和`CFRunLoopSourceCreate`方法的第三个参数都是指针，那么在Swift中，将对象转换为指针的方法有两种：
- 使用`unsafeBitCast`方法，该方法会将第一个参数的内容按照第二个参数的类型进行转换。一般当需要对象与指针来回转换时使用该方法。
- 在对象前面加`&`符号，表示传入指针地址。

当主线程的自定义事件源初始化完成之后，调用`addToCurrentRunLoop()`方法，将事件源添加至当前Run Loop中，即主线程的Run Loop：

```swift
let cfrunloop = CFRunLoopGetCurrent()
        
if let rls = runloopSource {
            
    CFRunLoopAddSource(cfrunloop, rls, kCFRunLoopDefaultMode)
            
}
```

接下来创建二级线程，并且让其执行二级线程的配置任务：

```swift
let secondaryThread = NSThread(target: self, selector: "startThreadWithRunloop", object: nil)
        
secondaryThread.start()
```

在二级线程中同样初始化自定义事件源，并将将其添加至二级线程的Run Loop中，然后启动Run Loop：

```swift
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
```

### 执行事件源的schedule回调函数
前文中说过将事件源添加至Run Loop后会触发事件源的`schedule`回调函数，所以当执行完`mainThreadRunLoopSource.addToCurrentRunLoop()`这句代码后，便会触发主线程自定义事件源的`schedule`回调函数：

```swift
func runloopSourceScheduleRoutine() -> @convention(c) (UnsafeMutablePointer<Void>, CFRunLoop!, CFString!) -> Void {
        
    return { (info, runloop, runloopMode) -> Void in
        
        let mainThreadRunloopSource = unsafeBitCast(info, MainThreadRunLoopSource.self)
            
        let mainThreadRunloopSourceContext = MainThreadRunLoopSourceContext(runloop: runloop, runloopSource: mainThreadRunloopSource)
            
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
        appDelegate.performSelector("registerMainThreadRunLoopSource:", withObject: mainThreadRunloopSourceContext)
        
    }
        
}
```

这里还需注意的是在Swift2.0中，如果一个作为回调函数方法的返回类型是指向函数的指针，这类指针可以转换为闭包，并且要在闭包前面加上`@convention(c)`标注。在`runloopSourceScheduleRoutine()`方法中，获取到主线程事件源对象并初始化事件源上下文对象，然后将该事件源上下文对象传给`AppDelegate`的对应方法注册该事件源上下文对象：

```swift
func registerMainThreadRunLoopSource(runloopSourceContext: MainThreadRunLoopSourceContext) {
        
    mainThreadRunloopSourceContext = runloopSourceContext
        
}
```

自然当在二级线程中执行完`secondaryThreadRunLoopSource.addToCurrentRunLoop()`这句代码后，也会触发二级线程自定义事件源的`schedule`回调函数：

```swift
func runloopSourceScheduleRoutine() -> @convention(c) (UnsafeMutablePointer<Void>, CFRunLoop!, CFString!) -> Void {
        
    return { (info, runloop, runloopMode) -> Void in
            
        let secondaryThreadRunloopSource = unsafeBitCast(info, SecondaryThreadRunLoopSource.self)
            
        let secondaryThreadRunloopSourceContext = SecondaryThreadRunLoopSourceContext(runloop: runloop, runloopSource: secondaryThreadRunloopSource)
            
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
        appDelegate.performSelectorOnMainThread("registerSecondaryThreadRunLoopSource:", withObject: secondaryThreadRunloopSourceContext, waitUntilDone: true)
            
    }
        
}
```

这里要注意的是，在该方法中同样是将二级线程事件源上下文对象传给了`AppDelegate`的对应方法，但是这里用了`performSelectorOnMainThread`方法，让其在主线程中执行，目的在于注册完上下文对象后就接着从主线程给二级线程发送事件消息了，其实我将这里作为了主线程触发二级线程执行任务的触发点：

```swift
func registerSecondaryThreadRunLoopSource(runloopSourceContext: SecondaryThreadRunLoopSourceContext) {
        
    secondaryThreadRunloopSourceContext = runloopSourceContext
        
    sendCommandToSecondaryThread()
        
}
    
func sendCommandToSecondaryThread() {
        
    secondaryThreadRunloopSourceContext?.runloopSource?.commandBuffer?.append(mainThreadRunloopSourceContext!)
        
    secondaryThreadRunloopSourceContext?.runloopSource?.signalSourceAndWakeUpRunloop(secondaryThreadRunloopSourceContext!.runloop!)
        
}
```

从上述代码中可以看到在`sendCommandToSecondaryThread()`方法中，将主线程的事件源上下文放入了二级线程事件源的指令池中，这里我设计的是只要指令池中有内容就代表事件源需要执行后续任务了。然后执行了二级线程事件源的`signalSourceAndWakeUpRunloop()`方法，给其标记为待执行，并唤醒二级线程的Run Loop：

```swift
func signalSourceAndWakeUpRunloop(runloop: CFRunLoopRef) {
        
    CFRunLoopSourceSignal(runloopSource)
        
    CFRunLoopWakeUp(runloop)
        
}
```

### 执行事件源的perform回调函数
当二级线程事件源被标记并且二级线程Run Loop被唤醒后，就会触发事件源的`perform`回调函数：

```swift
func runloopSourcePerformRoutine() -> @convention(c) (UnsafeMutablePointer<Void>) -> Void {
        
    return { info -> Void in
            
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
        appDelegate.performSelector("performSecondaryThreadRunLoopSourceTask")
            
    }
        
}
```

二级线程事件源的`perform`回调函数会在当前线程，也就是二级线程中执行`AppDelegate`中的对应方法：

```swift
func performSecondaryThreadRunLoopSourceTask() {
        
    if secondaryThreadRunloopSourceContext!.runloopSource!.commandBuffer!.count > 0 {
            
        mainCollectionViewController!.generateRandomAlpha()
            
        let mainThreadRunloopSourceContext = secondaryThreadRunloopSourceContext!.runloopSource!.commandBuffer![0]
            
        secondaryThreadRunloopSourceContext!.runloopSource!.commandBuffer!.removeAll()
            
        mainThreadRunloopSourceContext.runloopSource?.commandBuffer?.append(secondaryThreadRunloopSourceContext!)
            
        mainThreadRunloopSourceContext.runloopSource?.signalSourceAndWakeUpRunloop(mainThreadRunloopSourceContext.runloop!)
            
    }
        
}
```

从上述代码中可以看到，先会判断二级线程事件源的指令池中有没有内容，如果有的话，那么执行计算`UICollectionViewCell`透明度的任务，然后从指令池中获取到主线程事件源上下文对象，将二级线程事件源上下文对象放入主线程事件源的指令池中，并将主线程事件源标记为待执行，然后唤醒主线程Run Loop。之后便会触发主线程事件源的`perform`回调函数：

```swift
func runloopSourcePerformRoutine() -> @convention(c) (UnsafeMutablePointer<Void>) -> Void {
        
    return { info -> Void in
            
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
        appDelegate.performSelector("performMainThreadRunLoopSourceTask")
        
    }
        
}
```

```swift
func performMainThreadRunLoopSourceTask() {
        
    if mainThreadRunloopSourceContext!.runloopSource!.commandBuffer!.count > 0 {
        
        mainThreadRunloopSourceContext!.runloopSource!.commandBuffer!.removeAll()
            
        mainCollectionViewController!.collectionView.reloadData()
            
        let timer = NSTimer(timeInterval: 1, target: self, selector: "sendCommandToSecondaryThread", userInfo: nil, repeats: false)
            
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
        
    }
        
}
```

在`performMainThreadRunLoopSourceTask()`方法中同样会先判断主线程事件源的指令池是否有内容，然后执行`MainCollectionViewController`中的刷新UI的方法，最后再次给二级线程发送事件消息，以此循环。大家可以下载源码，编译环境为Xcode7.2，然后可以自己试着在界面中添加一个**Stop**按钮，让事件源执行`cancel`回调函数。