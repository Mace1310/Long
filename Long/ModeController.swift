//
//  ModeController.swift
//  Long
//
//  Created by Matteo Carnelos on 12/05/2017.
//  Copyright © 2017 Matteo Carnelos. All rights reserved.
//

import UIKit

class ModeController: UIViewController, TransmissionsDelegate {
    
    let TransmissionsManager = Transmissions.T
    
    @IBOutlet weak var NormalButton: UIButton!
    @IBOutlet weak var BeginnerButton: UIButton!
    @IBOutlet weak var SportButton: UIButton!
    @IBOutlet weak var EcoButton: UIButton!
    @IBOutlet weak var AutoButton: UIButton!
    
    @IBOutlet weak var InfoIcon: UIImageView!
    @IBOutlet weak var InfoTitleLabel: UILabel!
    @IBOutlet weak var InfoDescriptionText: UITextView!
    @IBOutlet weak var InfoPageIndicator: UIPageControl!
    @IBOutlet weak var SetModeButton: UIButton!
    
    var selectedButton: UIButton!
    var selectedModeCode: UInt8 = 0x00
    var setModeCode: UInt8!
    
    var UpdateTimer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        TransmissionsManager.delegate = self
        selectedButton = NormalButton
        TransmissionsManager.requestModeCode()
        updateInfo()
        UpdateTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateValues), userInfo: nil, repeats: true);
    }
    
    func RPMResponseReceived(_ RPM1: UInt16, _ RPM2: UInt16) {}
    func boardNameResponseRecieved(_ BoardName: String) {}
    func systemStatusResponseRecieved(_ args: UInt8) {}
    func cellVoltagesResponseRecieved(_ Battery1: Transmissions.LipoBattery, _ Battery2: Transmissions.LipoBattery) {}
    func batteryPercentageResponseRecieved(_ BatteryPercentage: UInt8) {}
    
    func modeCodeResponseRecieved(_ args: UInt8) {
        if selectedButton != nil {
            selectedButton.setBackgroundImage(#imageLiteral(resourceName: "Rectangle"), for: .normal)
        }
        switch args {
        case 0x00:
            selectedButton = NormalButton
            break
        case 0x01:
            selectedButton = BeginnerButton
            break
        case 0x02:
            selectedButton = SportButton
            break
        case 0x03:
            selectedButton = EcoButton
            break
        case 0x04:
            selectedButton = AutoButton
            break
        default:
            break
        }
        selectedButton.setBackgroundImage(#imageLiteral(resourceName: "RectangleGreen"), for: .normal)
        setModeCode = args
        updateInfo()
    }
    
    @IBAction func normalButtonSelected(sender: UIButton) {
        selectedModeCode = 0x00
        updateInfo()
    }
    
    @IBAction func beginnerButtonSelected(sender: UIButton) {
        selectedModeCode = 0x01
        updateInfo()
    }
    
    @IBAction func sportButtonSelected(sender: UIButton) {
        selectedModeCode = 0x02
        updateInfo()
    }
    
    @IBAction func ecoButtonSelected(sender: UIButton) {
        selectedModeCode = 0x03
        updateInfo()
    }
    
    @IBAction func autoButtonSelected(sender: UIButton) {
        selectedModeCode = 0x04
        updateInfo()
    }
    
    @IBAction func setModeTouch(sender: UIButton) {
        TransmissionsManager.setModeCode(selectedModeCode)
    }
    
    func updateValues() {
        TransmissionsManager.requestModeCode()
        if Bluetooth.CB.isConnected == false {
            UpdateTimer.invalidate()
            UpdateTimer = nil
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func updateInfo() {
        switch selectedModeCode {
        case 0x00:
            let Description = "Questa modalità è consigliata per l'utilizzo di tutti i giorni, è il giusto compromesso tra consumi, velocità e durata."
            changeInfo(#imageLiteral(resourceName: "Skateboard"), "NORMAL MODE", Description, 0)
            if selectedButton == NormalButton { disableSetButton() }
            else { enableSetButton() }
            break
        case 0x01:
            let Description = "Questa modalità è particolarmente indicata per tutti coloro che utilizzano il longboard elettrico per la prima volta. L'accelerazione e la velocità massima sono ridotte."
            changeInfo(#imageLiteral(resourceName: "Star"), "BEGINNER MODE", Description, 1)
            if selectedButton == BeginnerButton { disableSetButton() }
            else { enableSetButton() }
            break
        case 0x02:
            let Description = "Modalità consigliata ai soli utenti esperti. Tramite questa opzione infatti verrà rilasciata tutta la potenza del longboard, togliendo ogni limite sulla velocità e sulla accelerazione."
            changeInfo(#imageLiteral(resourceName: "Speed"), "SPORT MODE", Description, 2)
            if selectedButton == SportButton { disableSetButton() }
            else { enableSetButton() }
            break
        case 0x03:
            let Description = "Tramite questa modalità è possibile viaggiare lunghe distanze con il minimo consumo di batteria. Tutti i sensori e moduli supplementari vengono disabilitati per ridurre al massimo i consumi."
            changeInfo(#imageLiteral(resourceName: "Leaf"), "ECO MODE", Description, 3)
            if selectedButton == EcoButton { disableSetButton() }
            else { enableSetButton() }
            break
        case 0x04:
            let Description = "Questa modalità è ancora in fase di beta-testing, per questo alcune funzionalità potrebbero dare problemi o non funzionare. Il concetto della AUTO MODE è quello di poter utilizzare il longboard senza l'utilizzo di controller o smartphone."
            changeInfo(#imageLiteral(resourceName: "Automatic"), "AUTO MODE", Description, 4)
            if selectedButton == AutoButton { disableSetButton() }
            else { enableSetButton() }
            break
        default:
            break
        }
    }
    
    func disableSetButton() {
        SetModeButton.isEnabled = false
        UIView.animate(withDuration: 0.5) { 
            self.SetModeButton.alpha = 0.5
        }
    }
    
    func enableSetButton() {
        SetModeButton.isEnabled = true
        UIView.animate(withDuration: 0.5) {
            self.SetModeButton.alpha = 1
        }
    }
    
    func changeInfo(_ icon: UIImage, _ title: String, _ description: String, _ pageNumber: Int) {
        UIView.animate(withDuration: 0.5, animations: {
            self.InfoIcon.alpha = 0
            self.InfoTitleLabel.alpha = 0
            self.InfoDescriptionText.alpha = 0
        }) { (finished) in
            self.InfoIcon.image = icon
            self.InfoTitleLabel.text = title
            self.InfoDescriptionText.text = description
            self.InfoPageIndicator.currentPage = pageNumber
            UIView.animate(withDuration: 0.5, animations: {
                self.InfoIcon.alpha = 1
                self.InfoTitleLabel.alpha = 1
                self.InfoDescriptionText.alpha = 1
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func downPressed(_ sender: Any) {
        UpdateTimer.invalidate()
        UpdateTimer = nil
        dismiss(animated: true, completion: nil)
    }

}
