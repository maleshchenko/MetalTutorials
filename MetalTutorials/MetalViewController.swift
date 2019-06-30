protocol MetalViewControllerDelegate: class {
    func updateLogic(timeSinceLastUpdate: CFTimeInterval)
    func renderObject(drawable: CAMetalDrawable)
}

class MetalViewController: UIViewController {
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var projectionMatrix: Matrix4!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer: CADisplayLink!
    var lastFrameTimestamp: CFTimeInterval = 0.0
    
    weak var metalViewControllerDelegate: MetalViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()

        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        view.layer.addSublayer(metalLayer)
        
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        commandQueue = device.makeCommandQueue()
        
        timer = CADisplayLink(target: self, selector: #selector(ViewController.newFrame(displayLink:)))
        timer.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let window = view.window {
            let scale = window.screen.nativeScale
            let layerSize = view.bounds.size

            view.contentScaleFactor = scale
            metalLayer.frame = CGRect(x: 0, y: 0, width: layerSize.width, height: layerSize.height)
            metalLayer.drawableSize = CGSize(width: layerSize.width * scale, height: layerSize.height * scale)
            
            projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
        }
    }
    
    func render() {
        guard let drawable = metalLayer?.nextDrawable() else { return }
        self.metalViewControllerDelegate?.renderObject(drawable: drawable)
    }
    
    @objc func newFrame(displayLink: CADisplayLink){
        
        if lastFrameTimestamp == 0.0 {
            lastFrameTimestamp = displayLink.timestamp
        }
        
        let elapsed: CFTimeInterval = displayLink.timestamp - lastFrameTimestamp
        lastFrameTimestamp = displayLink.timestamp
        
        gameloop(timeSinceLastUpdate: elapsed)
    }
    
    @objc func gameloop(timeSinceLastUpdate: CFTimeInterval) {
        autoreleasepool {
            self.render()
        }
    }
}
