import UIKit
import simd

class ViewController: MetalViewController, MetalViewControllerDelegate {
    var worldModelMatrix: float4x4!
    var objectToDraw: Cube!
    
    let panSensivity:Float = 5.0
    var lastPanLocation: CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        worldModelMatrix.rotateAroundX(float4x4.degrees(toRad: 25), y: 0.0, z: 0.0)
        
        objectToDraw = Cube(device: device, commandQ: commandQueue, textureLoader: textureLoader)
        self.metalViewControllerDelegate = self
        
        setupGestures()
    }
    
    func renderObjects(_ drawable:CAMetalDrawable) {
        objectToDraw.render(commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil)
    }
    
    func updateLogic(_ timeSinceLastUpdate: CFTimeInterval) {
        //objectToDraw.updateWithDelta(delta: timeSinceLastUpdate)
    }
    
    //MARK: - Gesture related
    func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ViewController.pan))
        self.view.addGestureRecognizer(pan)
    }
    
    @objc func pan(panGesture: UIPanGestureRecognizer) {
        if panGesture.state == UIGestureRecognizer.State.changed {
            let pointInView = panGesture.location(in: self.view)
            
            let xDelta = Float((lastPanLocation.x - pointInView.x) / self.view.bounds.width) * panSensivity
            let yDelta = Float((lastPanLocation.y - pointInView.y) / self.view.bounds.height) * panSensivity
            
            objectToDraw.rotationY -= xDelta
            objectToDraw.rotationX -= yDelta
            lastPanLocation = pointInView
        } else if panGesture.state == UIGestureRecognizer.State.began {
            lastPanLocation = panGesture.location(in: self.view)
        }
    }
}
