//
//  GoController.swift
//  Long
//
//  Created by Matteo Carnelos on 16/03/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import UIKit

class GoController: UIViewController, TransmissionsDelegate {
    
    @IBOutlet weak var GestureView: UIView!
    @IBOutlet weak var Gesture: UIGestureRecognizer!
    @IBOutlet weak var ThrottleBar: KDCircularProgress!
    @IBOutlet weak var ThrottleLabel: UILabel!
    @IBOutlet weak var RPM1Bar: KDCircularProgress!
    @IBOutlet weak var RPM1Label: UILabel!
    @IBOutlet weak var RPM2Bar: KDCircularProgress!
    @IBOutlet weak var RPM2Label: UILabel!
    @IBOutlet weak var SpeedLabel: UILabel!
    @IBOutlet weak var SpeedBar: KDCircularProgress!
    @IBOutlet weak var ConfirmLabel: UILabel!
    @IBOutlet weak var StateIcon: UIImageView!
    
    var StartPoint = CGPoint.zero
    var OldDeltaPosition: CGFloat = 0
    var InitialValue: CGFloat = 0
    var ThrottleValue: UInt8 = 0
    var DecellerateTimer: Timer!
    var UpdateTimer: Timer!
    
    var StartCircle = CircleView()
    var EndCircle = CircleView()
    var Line = CAShapeLayer()
    
    let BluetoothManager = Bluetooth.CB
    let TransmissionsManager = Transmissions.T

    override func viewDidLoad() {
        super.viewDidLoad()
        TransmissionsManager.delegate = self
        UpdateTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateValues), userInfo: nil, repeats: true);
    }
    
    func updateValues() {
        if BluetoothManager.isConnected {
            TransmissionsManager.requestRPM()
            updateStateIcon();
        }
        else {
            UpdateTimer.invalidate()
            UpdateTimer = nil
            self.navigationController!.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func updateStateIcon() {
        let strength = BluetoothManager.SignalStrength
        if strength >= -55 {
            StateIcon.image = #imageLiteral(resourceName: "HighConnection")
        }
        else if strength < -55 && strength >= -75 {
            StateIcon.image = #imageLiteral(resourceName: "MediumConnection")
        }
        else if strength < -75 && strength >= -85 {
            StateIcon.image = #imageLiteral(resourceName: "LowConnection")
        }
        else if strength < -85 {
            StateIcon.image = #imageLiteral(resourceName: "NoConnection")
        }
    }
    
    func batteryPercentageResponseRecieved(_ BatteryPercentage: UInt8) {}
    
    func cellVoltagesResponseRecieved(_ Battery1: Transmissions.LipoBattery, _ Battery2: Transmissions.LipoBattery) {}
    
    func boardNameResponseRecieved(_ BoardName: String) {}
    
    func systemStatusResponseRecieved(_ args: UInt8) {}
    
    func RPMResponseReceived(_ RPM1: UInt16, _ RPM2: UInt16) {
        RPM1Label.text = String(RPM1)
        RPM2Label.text = String(RPM2)
        RPM1Bar.animate(toAngle: (Double(RPM1) * 270)/10000, duration: 1, completion: nil)
        RPM2Bar.animate(toAngle: (Double(RPM2) * 270)/10000, duration: 1, completion: nil)
        let AverageRPM = Double(RPM1 + RPM2) / 2
        let Speed = AverageRPM * 0.0132
        SpeedLabel.text = String("\(Int(Speed)) Km/h")
        SpeedBar.animate(toAngle: Speed * 2.7, duration: 1, completion: nil)
    }

    @IBAction func backPressed(sender: UIButton) {
        if ConfirmLabel.alpha == 1 || ThrottleValue == 0 {
            UpdateTimer.invalidate()
            UpdateTimer = nil
            self.navigationController!.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        }
        else {
            Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.cancelConfirmLabel), userInfo: nil, repeats: false);
            UIView.animate(withDuration: 0.5, animations: {
                self.ConfirmLabel.alpha = 1
            })
        }
    }
    
    func cancelConfirmLabel() {
        UIView.animate(withDuration: 0.5, animations: {
            self.ConfirmLabel.alpha = 0
        })
    }
    
    @IBAction func panGestureRecognized(sender: UIPanGestureRecognizer) {
        if Gesture.state == .began {
            drawLine(c: Gesture.location(in: GestureView))
            drawStartCircle(c: Gesture.location(in: GestureView), r: 40)
            drawEndCircle(c: Gesture.location(in: GestureView), r: 20)
            StartPoint = Gesture.location(in: GestureView)
            if DecellerateTimer != nil {
                DecellerateTimer.invalidate()
                DecellerateTimer = nil
            }
            InitialValue = CGFloat(Double(ThrottleValue) * 4.5)
        }
        if Gesture.state == .changed {
            var GestureLocation = Gesture.location(in: GestureView)
            var DeltaPosition = (StartPoint.y - GestureLocation.y) + InitialValue
            updateStartCircle(s: (DeltaPosition - OldDeltaPosition)/10)
            if GestureLocation.y < 20 {
                GestureLocation.y = 20
            }
            updateEndCircle(p: GestureLocation)
            updateLine(start: StartPoint, end: GestureLocation)
            OldDeltaPosition = DeltaPosition
            if DeltaPosition > 450 {
                DeltaPosition = 450
            }
            if DeltaPosition < 0 {
                DeltaPosition = 0
            }
            ThrottleValue = UInt8(DeltaPosition / 4.5)
            ThrottleBar.angle = Double(DeltaPosition * 0.6)
            ThrottleLabel.text = "\(ThrottleValue) %"
            
            TransmissionsManager.setESC(ThrottleValue)
        }
        if Gesture.state == .ended {
            removeStartCircle()
            removeEndCircle()
            removeLine()
            ThrottleBar.animate(toAngle: 0, duration: Double(ThrottleValue) * 0.2, completion: nil)
            DecellerateTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.decellerate), userInfo: nil, repeats: true);
        }

    }
    
    func decellerate() {
        if ThrottleValue != 0 {
            ThrottleValue -= 1
        }
        else {
            DecellerateTimer.invalidate()
            DecellerateTimer = nil
        }
        ThrottleLabel.text = "\(ThrottleValue) %"
        
        TransmissionsManager.setESC(ThrottleValue)
    }
    
    func drawStartCircle(c: CGPoint, r: CGFloat) {
        StartCircle = CircleView(frame: CGRect(x: c.x, y: c.y, width: 0, height: 0))
        StartCircle.backgroundColor = UIColor.clear
        GestureView.addSubview(StartCircle)
        StartCircle.resizeCircleWithPulseAnimation(r * 2, duration: 0.4)
    }
    
    func drawEndCircle(c: CGPoint, r: CGFloat) {
        EndCircle = CircleView(frame: CGRect(x: c.x, y: c.y, width: 0, height: 0))
        EndCircle.circle.backgroundColor = UIColor.black
        EndCircle.backgroundColor = UIColor.clear
        GestureView.addSubview(EndCircle)
        EndCircle.resizeCircleWithPulseAnimation(r * 2, duration: 0.4)
    }
    
    func updateStartCircle(s: CGFloat) {
        StartCircle.resizeCircleWithPulseAnimation(s, duration: 0)
    }
    
    func updateEndCircle(p: CGPoint) {
        EndCircle.center = p
    }
    
    func removeStartCircle() {
        StartCircle.circlePulseAinmation(-StartCircle.circle.frame.width, duration: 0.4, completionBlock: {
            self.StartCircle.removeFromSuperview()
            self.Line.removeFromSuperlayer()
        })
    }
    
    func removeEndCircle() {
        EndCircle.circlePulseAinmation(-EndCircle.circle.frame.width, duration: 0.2) { 
            self.EndCircle.removeFromSuperview()
        }
    }
    
    func drawLine(c: CGPoint) {
        updateLine(start: c, end: c)
        Line.strokeColor = UIColor.black.cgColor
        Line.strokeEnd = 1
        Line.lineWidth = 2
        Line.lineJoin = kCALineJoinRound
        GestureView.layer.addSublayer(Line)
    }
    
    func updateLine(start: CGPoint, end: CGPoint) {
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        Line.path = linePath.cgPath
    }
    
    func removeLine() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.Line.strokeEnd = 0
        }, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
