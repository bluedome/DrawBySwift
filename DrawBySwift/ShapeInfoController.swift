//
//  ShapeInfoController.swift
//  DrawBySwift
//

import Cocoa

let sharedInstance = ShapeInfoController(windowNibName:"ShapeInfoController")

protocol ShapeInfoControllerDelegate {
    func shapeInfoControllerDidUpdate(controller:ShapeInfoController)
}

class ShapeInfoController: NSWindowController {

    class var sharedInspector: ShapeInfoController {
    return sharedInstance
    }
    
    @IBOutlet var lineWidthField: NSTextField
    @IBOutlet var lineWidthStepper: NSStepper
    @IBOutlet var lineColorWell: NSColorWell
    @IBOutlet var fillColorWell: NSColorWell
    
    var delegate: ShapeInfoControllerDelegate?
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }

    @IBAction func updateWidthAction(sender: NSStepper) {
        lineWidthField.doubleValue = sender.doubleValue
        self.delegate?.shapeInfoControllerDidUpdate(self)
    }
    
    @IBAction func updateLineColorAction(sender: NSColorWell) {
        self.delegate?.shapeInfoControllerDidUpdate(self)
    }

    @IBAction func updateFillColorAction(sender: NSColorWell) {
        self.delegate?.shapeInfoControllerDidUpdate(self)
    }

    // NSTextFieldDelegate
    func control(control: NSControl!, isValidObject obj: AnyObject!) -> Bool {
        if let strVal = obj as? String {
            if let width = strVal.toInt() {
                if width <= 30 && width > 0 {
                    lineWidthStepper.doubleValue = Double(width)
                    self.delegate?.shapeInfoControllerDidUpdate(self)
                    
                    return true
                }
            }
        }
        NSBeep()
        return false
    }
}
