//
//  RaytracerView.swift
//  MetalTracer
//
//  Created by Ingebretsen, Andrew (HBO) on 3/23/18.
//  Copyright © 2018 Drew Ingebretsen. All rights reserved.
//

import UIKit

protocol RaytracerViewDelegate {
    func raytracerViewDidCreateImage(image:UIImage)
    func raytracerViewDidSelectSphere(index:Int)
}

class RaytracerView: UIView {
    public var selectedSphere:Int = -1
    public var scene: Scene!
    public var samples: Int {
        return rayTracer.sampleNumber;
    }
    
    private var delegate:RaytracerViewDelegate?
    
    private var xResolution:Int = 0
    private var yResolution:Int = 0
    
    private var lastX:Float = 0
    private var lastY:Float = 0
    
    private var timer: CADisplayLink! = nil
    private var context:MetalContext! = nil
    
    private var imageTexture: MTLTexture! = nil
    
    private var rayTracer:Raytracer! = nil
    
    private var imageView: UIImageView = UIImageView()
    private var tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
    private var doubleTapRecognize = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction(_:)))
    private var pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
    private var panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
    

    
    override func layoutSubviews() {
        self.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.rightAnchor.constraint(equalTo: self.rightAnchor),
            imageView.leftAnchor.constraint(equalTo: self.leftAnchor),
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        
        addGestureRecognizer(pinchRecognizer)
        addGestureRecognizer(panRecognizer)
        addGestureRecognizer(tapRecognizer)
        addGestureRecognizer(doubleTapRecognizer)
    }
    
    func initialize() {
        xResolution = Int(bounds.width)
        yResolution = Int(bounds.height)
    
        //self.imageTexture = UIImage.textureFromImage(UIImage(named: "texture.jpg")!, context: context)
        
        var device = MTLCreateSystemDefaultDevice()
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            print("Metal is not supported on this device")
            return
        }
        context = MetalContext(device: device!)
        let camera = Camera(cameraUp:Vector3D(x:0.0, y:1.0, z:0.0), cameraPosition:Vector3D(x:0.0, y:0.0, z:3.0), aspectRatio:Float(bounds.width/bounds.height))
        scene = Scene(camera:camera, context:context)
        rayTracer = Raytracer(renderContext: context, xResolution: xResolution, yResolution: yResolution)
        rayTracer.imageTexture = imageTexture
    }
    
    public func startRendering() {
        restart()
        timer = CADisplayLink(target: self, selector: #selector(renderLoop))
        timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    @IBAction func pinchAction(_ sender: UIPinchGestureRecognizer) {
        scene.camera.cameraPosition = Matrix.transformPoint(Matrix.translate( scene.camera.cameraPosition * (Float(sender.velocity) * -0.1)), right: scene.camera.cameraPosition);
        sender.scale = 1.0;
        reset()
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self.imageView);
        let dx:Float = 1.0 / Float(xResolution);
        let dy:Float = 1.0 / Float(yResolution);
        let x:Float = -0.5 + Float(CGFloat(xResolution)-point.x)  * dx;
        let y:Float = -0.5 + Float(point.y)  * dy;
        let ray:Ray = scene.camera.getRay(x, y: y);
        selectedSphere = scene.getClosestHit(ray);
        delegate?.raytracerViewDidSelectSphere(index: selectedSphere)
    }
    
    @IBAction func doubleTapAction(_ sender: UITapGestureRecognizer) {
        if (scene.sphereCount >= 5){
            return;
        }
        
        let point = sender.location(in: self.imageView)
        let x = Float((((CGFloat(xResolution)-point.x)/CGFloat(xResolution)) * 2.0) - 1.0)
        let y = Float((((CGFloat(yResolution)-point.y)/CGFloat(yResolution)) * 2.0) - 1.0)
        
        /*let cosy = scene.camera.cameraUp ⋅ Vector3D.up()
         let cosx = scene.camera.cameraRight ⋅ Vector3D.right()
         let position:Vector3D = Matrix.transformPoint(matrix, right: Vector3D(x: x, y: y, z: 0));*/
        
        let angleX = acos(scene.camera.cameraRight ⋅ Vector3D.right()) / (scene.camera.cameraRight.length() * Vector3D.right().length())
        let angleY = acos(scene.camera.cameraUp ⋅ Vector3D.up()) / (scene.camera.cameraUp.length() * Vector3D.up().length())
        
        let matrix = Matrix.rotateY(angleX) * Matrix.rotateX(angleY)
        let position:Vector3D = Matrix.transformPoint(matrix, right: Vector3D(x: x, y: y, z: 0))
        scene.addSphere(Sphere(position: position, radius:0.25, color:Vector3D(x: 0.75, y: 0.75, z: 0.75), material: Material.diffuse))
        restart()
    }
    
    @IBAction func panAction(_ sender: UIPanGestureRecognizer) {
        let point = sender.location(in: self.imageView);
        let x = Float((((CGFloat(xResolution)-point.x)/CGFloat(xResolution)) * 2.0) - 1.0);
        let y = Float((((CGFloat(yResolution)-point.y)/CGFloat(yResolution)) * 2.0) - 1.0);
        let xDelta:Float = x - lastX;
        let yDelta:Float = y - lastY;
        
        if (selectedSphere > -1){
            let currentPosition:Vector3D = scene.spheres[selectedSphere].position;
            let matrix:Matrix = Matrix.translate(scene.camera.cameraRight * xDelta) * Matrix.translate(scene.camera.cameraUp * yDelta);
            scene.spheres[selectedSphere].position = Matrix.transformPoint(matrix, right: currentPosition);
        } else{
            let velocity = sender.velocity(in: self.imageView);
            let xVelocity = Float(velocity.x/(.pi * CGFloat(xResolution)));
            let yVelocity = Float(velocity.y/(.pi * CGFloat(yResolution)));
            
            /*let matrix:Matrix = Matrix.rotateY(xVelocity) * Matrix.rotate(self.scene.camera.cameraRight, angle:-yVelocity)
             self.scene.camera.cameraUp = Matrix.transformVector(matrix, right: self.scene.camera.cameraUp);
             self.scene.camera.cameraPosition = Matrix.transformPoint(matrix, right: self.scene.camera.cameraPosition)*/
            
            let yMatrix:Matrix = Matrix.rotate(scene.camera.cameraRight, angle:-yVelocity)
            scene.camera.cameraUp = Matrix.transformVector(yMatrix, right: scene.camera.cameraUp);
            scene.camera.cameraPosition = Matrix.transformPoint(yMatrix, right: scene.camera.cameraPosition)
            
            let xMatrix:Matrix = Matrix.rotateY(xVelocity);
            scene.camera.cameraUp = Matrix.transformVector(xMatrix, right: scene.camera.cameraUp);
            scene.camera.cameraPosition = Matrix.transformPoint(xMatrix, right: scene.camera.cameraPosition)
        }
        
        lastX = x;
        lastY = y;
        reset()
    }
    
    var que:DispatchQueue = DispatchQueue(label: "Rendering", attributes: []);
    
    @objc func renderLoop() {
        autoreleasepool {
            self.que.async(execute: {
                let image:UIImage = self.rayTracer.renderScene(self.scene);
                DispatchQueue.main.async(execute: {
                    self.imageView.image = image
                    //self.sampleLabel.text = "Pass:\(self.rayTracer.sampleNumber)"
                });
            });
            
            
        }
    }
    
    func reset() {
        scene?.resetBuffer()
        rayTracer.sampleNumber = 1
    }
    
    func restart() {
        reset()
        rayTracer?.reset()
    }
}
