//
//  AppDelegate.swift
//  DrawBySwift
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, ShapeInfoControllerDelegate {
                            
    @IBOutlet var window: NSWindow?
    @IBOutlet var drawView: DrawView?
    @IBOutlet var drawTypeSegment: NSSegmentedControl?
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        drawView!.shapeSelectedHandler = { shape in
            if ShapeInfoController.sharedInspector.window.visible {
                self.setShapeInfo(shape)
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }

    // Actions
    
    @IBAction func drawSegmentAction(sender: NSSegmentedControl) {
        if let dtype = DrawShapeType.fromRaw(sender.selectedSegment) {
            drawView!.drawType = dtype
        }
    }
    
    @IBAction func clearAction(sender: NSButton) {
        drawView!.drawContents.removeAll()
        drawView!.currentShapeTool = nil
        drawView!.needsDisplay = true
    }

    @IBAction func inspectorAction(sender: NSButton) {
        let inspector = ShapeInfoController.sharedInspector
        inspector.delegate = self
        
        inspector.showWindow(self)
        self.setShapeInfo(drawView?.currentShapeTool?.shape)
    }

    func setShapeInfo(shape:DrawShape?) {
        let inspector = ShapeInfoController.sharedInspector
        if !inspector.windowLoaded {
            return
        }
        
        if shape {
            inspector.lineWidthField!.enabled = true
            inspector.lineWidthStepper!.enabled = true
            inspector.lineColorWell!.enabled = true
            inspector.fillColorWell!.enabled = true
            
            inspector.lineWidthField!.doubleValue = shape!.lineWidth
            inspector.lineWidthStepper!.doubleValue = shape!.lineWidth
            inspector.lineColorWell!.color = shape!.lineColor
            inspector.fillColorWell!.color = shape!.color
            
            switch (shape!.type) {
            case .Line:
                inspector.fillColorWell!.enabled = false
            default:
                inspector.fillColorWell!.enabled = true
            }
            
            inspector.window.title = shape!.type.description
            
        } else {
            inspector.lineWidthField!.enabled = false
            inspector.lineWidthStepper!.enabled = false
            inspector.lineColorWell!.enabled = false
            inspector.fillColorWell!.enabled = false
            
            inspector.window.title = "No Selected"
        }
    }
    
    // ShapeInfoControllerDelegate
    
    func shapeInfoControllerDidUpdate(controller:ShapeInfoController) {
        if let shape = drawView?.currentShapeTool?.shape {
            let dict: NSDictionary = ["shape": shape, "fillColor":shape.color, "lineColor": shape.lineColor, "lineWidth": shape.lineWidth]
            drawView!.undoManager.prepareWithInvocationTarget(self).undoShapeInfo(dict)

            shape.lineWidth = controller.lineWidthStepper!.doubleValue
            shape.lineColor = controller.lineColorWell!.color
            shape.color = controller.fillColorWell!.color
            
            drawView!.needsDisplay = true
        }
    }

    // for undo
    
    func undoShapeInfo(info:NSDictionary) {
        let shape = info["shape"] as DrawShape
        let color = info["fillColor"] as NSColor
        let lineColor = info["lineColor"] as NSColor
        let width = info["lineWidth"] as CGFloat
        
        shape.color = color
        shape.lineColor = lineColor
        shape.lineWidth = Double(width)
        
        if let selected = drawView?.currentShapeTool?.shape {
            if selected === shape {
                // update ui
                self.setShapeInfo(shape)
            }
        }
        
        // for redo
        if let dView = drawView {
            dView.undoManager.prepareWithInvocationTarget(self).undoShapeInfo(info)
        
            dView.needsDisplay = true
        }
    }
}

