//
//  ViewController.swift
//  GazeRemote
//
//  Created by Tommy on 2021/07/08.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: Variables
    var irisTracker: MPIrisTrackerH!
    var documentInteraction: UIDocumentInteractionController!
    var leftEye: Eye?
    var rightEye: Eye?
    
    @IBOutlet var rightInfoLabel: UILabel!
    @IBOutlet var leftInfoLabel: UILabel!
    
    var mouseView: UIView!
    let screenSize = UIScreen.main.bounds.size
    var topBarHeight: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
    
    let natureRemo = NatureRemo()
    var timer: Timer?
    var timerCount = 0.0
    
    // MARK: Life cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        irisTracker = MPIrisTrackerH()
        irisTracker.delegate = self
        irisTracker.start()
        
        mouseView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        mouseView.center = self.view.center
        mouseView.backgroundColor = UIColor.gray
        mouseView.layer.cornerRadius = 25
        mouseView.layer.shadowColor = UIColor.black.cgColor
        mouseView.layer.shadowOpacity = 1
        mouseView.layer.shadowRadius = 4
        mouseView.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.view.addSubview(mouseView)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.mouseView.center = self.view.center
    }
    
    func moveMouse(x: CGFloat, y: CGFloat) {
        mouseView.center.x += x * 20
        mouseView.center.y -= y * 20
        
        if mouseView.center.x >= screenSize.width - (mouseView.frame.width / 2) {
            mouseView.center.x = screenSize.width - (mouseView.frame.width / 2)
        }
        if mouseView.center.y >= screenSize.height - (mouseView.frame.height / 2) {
            mouseView.center.y = screenSize.height - (mouseView.frame.height / 2)
        }
        if mouseView.center.x <= (mouseView.frame.height / 2) {
            mouseView.center.x = mouseView.frame.height / 2
        }
        if mouseView.center.y <= topBarHeight + (mouseView.frame.height / 2) {
            mouseView.center.y = 0 + topBarHeight + (mouseView.frame.height / 2)
        }
    }
    
    func blinkingDetection() {
        if (self.leftEye?.isBlinking() ?? false) && (self.rightEye?.isBlinking() ?? false) && timer == nil {
            self.mouseView.backgroundColor = .red
            self.timer = Timer.scheduledTimer(
                timeInterval: 0.5,
                target: self,
                selector: #selector(self.timerCounter),
                userInfo: nil,
                repeats: true)
        } else if !(self.leftEye?.isBlinking() ?? true) && !(self.rightEye?.isBlinking() ?? true) && timer != nil {
            timer!.invalidate()
            self.mouseView.backgroundColor = .gray
            if timerCount > 1.5 {
                pressButton()
            }
            timer = nil
            timerCount = 0.0
        }
    }
    
    func pressButton() {
        if self.mouseView.center.y > (self.screenSize.height / 2) {
            if self.mouseView.center.x > (self.screenSize.width / 2) {
                natureRemo.pressButton(buttonId: "minus")
            } else {
                natureRemo.pressButton(buttonId: "plus")
            }
        } else {
            if self.mouseView.center.x > (self.screenSize.width / 2) {
                natureRemo.pressButton(buttonId: "input")
            } else {
                natureRemo.pressButton(buttonId: "power")
            }
        }
    }
    
    @objc func timerCounter() {
        timerCount += 0.5
    }
}

// MARK: Iris Detector Delegate Method
extension ViewController: MPTrackerDelegate {
    func faceMeshDidUpdate(_ tracker: MPIrisTrackerH!, didOutputLandmarks landmarks: [MPLandmark]!, timestamp: Int) {
        self.leftEye = Eye(left: landmarks[33], right: landmarks[133], top: landmarks[159], bottom: landmarks[145])
        self.rightEye = Eye(left: landmarks[398], right: landmarks[263], top: landmarks[386], bottom: landmarks[374])
    }
    
    func irisTrackingDidUpdate(_ tracker: MPIrisTrackerH!, didOutputLandmarks landmarks: [MPLandmark]!, timestamp: Int) {
        DispatchQueue.main.async {
            if self.leftEye != nil && self.rightEye != nil {
                let relativeCoordinateLeft = self.leftEye!.calculateRelativePosition(iris: landmarks[0])
                self.leftInfoLabel.text = "L(\(String(format: "%01.2f", relativeCoordinateLeft.x)), \(String(format: "%01.2f", relativeCoordinateLeft.y)))"
                
                let relativeCoordinateRight = self.rightEye!.calculateRelativePosition(iris: landmarks[5])
                self.rightInfoLabel.text = "R(\(String(format: "%01.2f", relativeCoordinateRight.x)), \(String(format: "%01.2f", relativeCoordinateRight.y)))"
                
                if !(self.leftEye?.isBlinking() ?? false) && !(self.rightEye?.isBlinking() ?? false) {
                    self.moveMouse(x: CGFloat(relativeCoordinateLeft.x + relativeCoordinateRight.x), y: CGFloat(relativeCoordinateLeft.y + relativeCoordinateRight.y))
                }
                
                self.blinkingDetection()
            }
        }
    }
    
    func frameWillUpdate(_ tracker: MPIrisTrackerH!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!, timestamp: Int) {
        // Pixel Buffer is original image
    }
    
    func frameDidUpdate(_ tracker: MPIrisTrackerH!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        // Pixel Buffer is anotated image
    }
}
