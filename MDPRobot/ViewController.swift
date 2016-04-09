//
//  ViewController.swift
//  MDPRobot
//
//  Created by Kevin Coble on 3/30/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa
import AIToolbox

class ViewController: NSViewController {

    @IBOutlet weak var worldView: WorldView!
    @IBOutlet weak var editRadioButton: NSButton!
    @IBOutlet weak var runRadioButton: NSButton!
    @IBOutlet weak var polygonOrderTextField: NSTextField!
    @IBOutlet weak var polygonOrderStepper: NSStepper!
    @IBOutlet weak var crossTermCheckbox: NSButton!
    @IBOutlet weak var goalCheckbox1: NSButton!
    @IBOutlet weak var goalCheckbox2: NSButton!
    @IBOutlet weak var goalCheckbox3: NSButton!
    @IBOutlet weak var goalCheckbox4: NSButton!
    @IBOutlet weak var pitCheckbox1: NSButton!
    @IBOutlet weak var pitCheckbox2: NSButton!
    @IBOutlet weak var pitCheckbox3: NSButton!
    @IBOutlet weak var pitCheckbox4: NSButton!
    @IBOutlet weak var obstacleCheckbox1: NSButton!
    @IBOutlet weak var obstacleCheckbox2: NSButton!
    @IBOutlet weak var obstacleCheckbox3: NSButton!
    @IBOutlet weak var obstacleCheckbox4: NSButton!
    @IBOutlet weak var obstacleCheckbox5: NSButton!
    @IBOutlet weak var obstacleCheckbox6: NSButton!
    @IBOutlet weak var obstacleCheckbox7: NSButton!
    @IBOutlet weak var obstacleCheckbox8: NSButton!
    @IBOutlet weak var obstacleCheckbox9: NSButton!
    @IBOutlet weak var obstacleCheckbox10: NSButton!
    @IBOutlet weak var rotateCCWButton: NSButton!
    @IBOutlet weak var rotateCWButton: NSButton!
    
    var runTimer : NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func onModeChanged(sender: NSButton) {
        let newEditMode = (sender.tag == 0)
        worldView.editMode = newEditMode
        
        //  Enable/Disable edit buttons
        polygonOrderTextField.enabled = newEditMode
        polygonOrderStepper.enabled = newEditMode
        crossTermCheckbox.enabled = newEditMode
        goalCheckbox1.enabled = newEditMode
        goalCheckbox2.enabled = newEditMode
        goalCheckbox3.enabled = newEditMode
        goalCheckbox4.enabled = newEditMode
        pitCheckbox1.enabled = newEditMode
        pitCheckbox2.enabled = newEditMode
        pitCheckbox3.enabled = newEditMode
        pitCheckbox4.enabled = newEditMode
        obstacleCheckbox1.enabled = newEditMode
        obstacleCheckbox2.enabled = newEditMode
        obstacleCheckbox3.enabled = newEditMode
        obstacleCheckbox4.enabled = newEditMode
        obstacleCheckbox5.enabled = newEditMode
        obstacleCheckbox6.enabled = newEditMode
        obstacleCheckbox7.enabled = newEditMode
        obstacleCheckbox8.enabled = newEditMode
        obstacleCheckbox9.enabled = newEditMode
        obstacleCheckbox10.enabled = newEditMode
        rotateCCWButton.enabled = newEditMode
        rotateCWButton.enabled = newEditMode
        
        worldView.setNeedsDisplayInRect(worldView.bounds)
        
        //  Start or stop the run timer
        if (newEditMode) {
            runTimer?.invalidate()
        }
        else {
            //  Get the policy
            worldView.getActionPolicy()
            
            //  Start the animation timert
            runTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(processRunTimer), userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func onPolygonOrderFieldChanged(sender: NSTextField) {
        polygonOrderStepper.integerValue = polygonOrderTextField.integerValue
        worldView.changeModel(polygonOrderTextField.integerValue, withCrossTerms: crossTermCheckbox == NSOnState)
    }
    
    @IBAction func onPolygonOrderStepperChanged(sender: NSStepper) {
        polygonOrderTextField.integerValue = polygonOrderStepper.integerValue
        worldView.changeModel(polygonOrderStepper.integerValue, withCrossTerms: crossTermCheckbox == NSOnState)
    }

    @IBAction func onCrossTermChanged(sender: NSButton) {
        worldView.changeModel(polygonOrderTextField.integerValue, withCrossTerms: crossTermCheckbox == NSOnState)
    }
    
    @IBAction func onGoalCheckboxChange(sender: NSButton) {
        worldView.goalEnabled[sender.tag] = (sender.state == NSOnState)
        worldView.setNeedsDisplayInRect(worldView.bounds)
    }
    
    @IBAction func onPitCheckboxChange(sender: NSButton) {
        worldView.pitEnabled[sender.tag] = (sender.state == NSOnState)
        worldView.setNeedsDisplayInRect(worldView.bounds)
    }
    
    @IBAction func onObstacleCheckboxChange(sender: NSButton) {
        worldView.obstacleEnabled[sender.tag] = (sender.state == NSOnState)
        worldView.setNeedsDisplayInRect(worldView.bounds)
    }
    
    @IBAction func onTurnRobotCCW(sender: NSButton) {
        worldView.robotAngle += 10.0
        if (worldView.robotAngle >= 180.0) { worldView.robotAngle -= 360.0 }
        worldView.setNeedsDisplayInRect(worldView.bounds)
    }
    
    @IBAction func onTurnRobotCW(sender: NSButton) {
        worldView.robotAngle -= 10.0
        if (worldView.robotAngle <= -180.0) { worldView.robotAngle += 360.0 }
        worldView.setNeedsDisplayInRect(worldView.bounds)
    }
    
    func processRunTimer() {
        //  Get the recommended action from the policy
        let action = worldView.getCurrentAction()
        if (!worldView.simulateAction(action, forTime: 0.05)) {
            //  We hit an end position, stop the run mode
            editRadioButton.state = NSOnState
            onModeChanged(editRadioButton)
        }
        worldView.setNeedsDisplayInRect(worldView.bounds)
    }

}

