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
    @IBOutlet weak var ThrottleLabelInfo: UILabel!
    @IBOutlet weak var RPM1Bar: KDCircularProgress!
    @IBOutlet weak var RPM1Label: UILabel!
    @IBOutlet weak var RPM2Bar: KDCircularProgress!
    @IBOutlet weak var RPM2Label: UILabel!
    @IBOutlet weak var SpeedLabel: UILabel!
    @IBOutlet weak var SpeedLabelInfo: UILabel!
    @IBOutlet weak var SpeedBar: KDCircularProgress!
    @IBOutlet weak var ConfirmLabel: UILabel!
    @IBOutlet weak var StateIcon: UIImageView!
    @IBOutlet weak var CruiseControlIcon: UIImageView!
    @IBOutlet weak var CruiseControlButton: UIButton!
    @IBOutlet weak var CruiseControlSwitch: UISwitch!
    @IBOutlet weak var Current1Label: UILabel!
    @IBOutlet weak var Current2Label: UILabel!
    @IBOutlet weak var CurrentBar: UIProgressView!
    @IBOutlet weak var AutonomyLabel: UILabel!
    @IBOutlet weak var BatteryPercentageLabel: UILabel!
    @IBOutlet weak var BatteryPercentageIcon: UIImageView!
    @IBOutlet weak var ModeLabel: UILabel!
    @IBOutlet weak var ModeIcon: UIImageView!
    
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
    
    var Battery_Percentage = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        TransmissionsManager.delegate = self
        UpdateTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateValues), userInfo: nil, repeats: true);
    }
    
    func updateValues() {
        if BluetoothManager.isConnected {
            TransmissionsManager.requestRPM()
            TransmissionsManager.requestCurrent()
            TransmissionsManager.requestBatteryPercentage()
            TransmissionsManager.requestModeCode()
            updateStateIcon()
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
    
    func cellVoltagesResponseRecieved(_ Battery1: Transmissions.LipoBattery, _ Battery2: Transmissions.LipoBattery) {}
    func boardNameResponseRecieved(_ BoardName: String) {}
    func systemStatusResponseRecieved(_ SystemStatus: UInt8) {}
    
    func modeCodeResponseRecieved(_ ModeCode: UInt8) {
        switch ModeCode {
        case 0x00:
            ModeLabel.text = "NORMAL"
            ModeIcon.image = #imageLiteral(resourceName: "Skateboard")
            break
        case 0x01:
            ModeLabel.text = "BEGINNER"
            ModeIcon.image = #imageLiteral(resourceName: "Star")
            break
        case 0x02:
            ModeLabel.text = "SPORT"
            ModeIcon.image = #imageLiteral(resourceName: "Speed")
            break
        case 0x03:
            ModeLabel.text = "ECO"
            ModeIcon.image = #imageLiteral(resourceName: "Leaf")
            break
        case 0x04:
            ModeLabel.text = "AUTO"
            ModeIcon.image = #imageLiteral(resourceName: "Automatic")
            break
        default:
            break
        }
    }
    
    func batteryPercentageResponseRecieved(_ BatteryPercentage: UInt8) {
        Battery_Percentage = Int(BatteryPercentage)
        if Battery_Percentage == 101 {
            BatteryPercentageLabel.text = "ERROR"
            BatteryPercentageIcon.image = #imageLiteral(resourceName: "BatteryError")
        }
        else {
            BatteryPercentageLabel.text = "\(Battery_Percentage)%"
            if Battery_Percentage <= 10 {
                BatteryPercentageIcon.image = #imageLiteral(resourceName: "Battery0%")
            }
            else if Battery_Percentage > 10 && Battery_Percentage <= 25 {
                BatteryPercentageIcon.image = #imageLiteral(resourceName: "Battery25%")
            }
            else if Battery_Percentage > 25 && Battery_Percentage <= 50 {
                BatteryPercentageIcon.image = #imageLiteral(resourceName: "Battery50%")
            }
            else if Battery_Percentage > 50 && Battery_Percentage <= 75 {
                BatteryPercentageIcon.image = #imageLiteral(resourceName: "Battery75%")
            }
            else if Battery_Percentage > 75 && Battery_Percentage <= 100 {
                BatteryPercentageIcon.image = #imageLiteral(resourceName: "Battery100%")
            }
        }
    }
    
    func currentResponseRecieved(_ Current1: Float32, _ Current2: Float32) {
        let Current1_INT = Int(Current1)
        let Current2_INT = Int(Current2)
        Current1Label.text = String("\(Current1_INT) A")
        Current2Label.text = String("\(Current2_INT) A")
        let Current_SUM = Current1_INT + Current2_INT
        if Current_SUM < 50 {
            CurrentBar.progressTintColor = UIColor(red:0.15, green:0.68, blue:0.38, alpha:1.0)
        }
        else if Current_SUM > 50 && Current_SUM < 100 {
            CurrentBar.progressTintColor = UIColor(red:0.83, green:0.33, blue:0.00, alpha:1.0)
        }
        else {
            CurrentBar.progressTintColor = UIColor(red:0.75, green:0.22, blue:0.17, alpha:1.0)
        }
        CurrentBar.setProgress(Float(Current_SUM / 150), animated: true)
        if Current_SUM <= 1 { AutonomyLabel.text = "∞" }
        else {
            if Battery_Percentage != 101  && Battery_Percentage != 0 {
                let RemainingCapacity = (Battery_Percentage * 10) / 100
                let Autonomy = Int((RemainingCapacity * 60) / Current_SUM)
                let AutonomyHours = Int(Autonomy / 60)
                let AutonomyMinutes = Int(Autonomy % 60)
                AutonomyLabel.text = "\(AutonomyHours) h \(AutonomyMinutes) min"
            }
            else {
                AutonomyLabel.text = "- h - min"
            }
        }
    }
    
    func RPMResponseReceived(_ RPM1: UInt16, _ RPM2: UInt16) {
        RPM1Label.text = String(RPM1)
        RPM2Label.text = String(RPM2)
        RPM1Bar.animate(toAngle: (Double(RPM1) * 270)/10000, duration: 1, completion: nil)
        RPM2Bar.animate(toAngle: (Double(RPM2) * 270)/10000, duration: 1, completion: nil)
        let AverageRPM = Double(RPM1 + RPM2) / 2
        let Speed = ((AverageRPM / 2.13) * 0.035 * 0.10472) * 3.6
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
    
    @IBAction func emergencyStopPressed(sender: UIButton) {
        TransmissionsManager.emergencyStop()
        if DecellerateTimer != nil {
            DecellerateTimer.invalidate()
            DecellerateTimer = nil
        }
        ThrottleLabel.textColor = UIColor(red:0.75, green:0.22, blue:0.17, alpha:1.0)
        ThrottleLabel.text = "STOP"
        ThrottleBar.progressColors = [UIColor(red:0.75, green:0.22, blue:0.17, alpha:1.0)]
        ThrottleBar.animate(toAngle: 270, duration: 1, completion: nil)
        ThrottleLabelInfo.textColor = UIColor(red:0.75, green:0.22, blue:0.17, alpha:1.0)
        ThrottleValue = 0
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
            ThrottleLabel.textColor = UIColor.black
            ThrottleLabelInfo.textColor = UIColor.black
            ThrottleBar.progressColors = [UIColor.black]
            disableCruiseControl(false)
            CruiseControlSwitch.setOn(false, animated: true)
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
    
    @IBAction func DoubleTapRecognized(sender: UITapGestureRecognizer) {
        CruiseControlButtonPressed(sender: CruiseControlButton)
    }
    
    @IBAction func CruiseControlButtonPressed(sender: UIButton) {
        if CruiseControlSwitch.isOn {
            CruiseControlSwitch.setOn(false, animated: true)
            disableCruiseControl(true)
        }
        else {
            CruiseControlSwitch.setOn(true, animated: true)
            enableCruiseControl()
        }
    }
    
    @IBAction func CruiseControlSwitchPressed(sender: UISwitch) {
        if CruiseControlSwitch.isOn {
            enableCruiseControl()
        }
        else {
            disableCruiseControl(true)
        }

    }
    
    func enableCruiseControl() {
        CruiseControlButton.setTitleColor(UIColor(red:0.15, green:0.68, blue:0.38, alpha:1.0), for: .normal)
        CruiseControlIcon.image = #imageLiteral(resourceName: "CruiseControlON")
        SpeedLabel.textColor = UIColor(red:0.15, green:0.68, blue:0.38, alpha:1.0)
        SpeedLabelInfo.textColor = UIColor(red:0.15, green:0.68, blue:0.38, alpha:1.0)
        SpeedBar.progressColors = [UIColor(red:0.15, green:0.68, blue:0.38, alpha:1.0)]
        SpeedBar.angle = 270
        if DecellerateTimer != nil {
            DecellerateTimer.invalidate()
            DecellerateTimer = nil
        }
        ThrottleBar.angle = Double(ThrottleValue) * 0.2
    }
    
    func disableCruiseControl(_ goToZero: Bool) {
        CruiseControlButton.setTitleColor(.black, for: .normal)
        CruiseControlIcon.image = #imageLiteral(resourceName: "CruiseControlOFF")
        SpeedLabel.textColor = UIColor.black
        SpeedLabelInfo.textColor = UIColor.black
        SpeedBar.progressColors = [UIColor.black]
        SpeedBar.angle = 270
        if goToZero {
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
