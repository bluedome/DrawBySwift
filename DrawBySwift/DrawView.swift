//
//  DrawView.swift
//  DrawBySwift
//

import Cocoa

class DrawView: NSView {
    var drawContents: [DrawShape] = []
    var drawType: DrawShapeType = .Line
    var currentShapeTool: BaseShapeTool? {
    didSet {
        if !currentShapeTool {
            // to nil
            self.shapeSelectedHandler?(shape: nil)
        }
    }
    }
    var trackingArea: NSTrackingArea?
    
    var copiedShape: DrawShape?
    var pasteCount = 0
    
    var createdShape = false
    var preVertices: [NSPoint]?
    
    var shapeSelectedHandler: ((shape: DrawShape?) -> ())?
    
    init(frame: NSRect) {
        super.init(frame: frame)
        // Initialization code here.
        
        trackingArea = NSTrackingArea(rect:self.bounds, options:.MouseMoved | .ActiveInActiveApp, owner:self, userInfo:nil)
        self.addTrackingArea(trackingArea)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        self.removeTrackingArea(trackingArea)
        trackingArea = NSTrackingArea(rect:self.bounds, options:.MouseMoved | .ActiveInActiveApp, owner:self, userInfo:nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func drawRect(dirtyRect: NSRect) {
        // Drawing code here.
        NSColor.whiteColor().set()
        NSRectFill(self.bounds)

        if drawContents.count == 0 {
            return
        }
        
        let gport = NSGraphicsContext.currentContext().graphicsPort
        let context = Unmanaged<CGContext>.fromOpaque(COpaquePointer(gport)).takeUnretainedValue()
        
        CGContextSetStrokeColorWithColor(context, NSColor.blackColor().CGColor)
//        NSLog("count=%d", drawContents.count)
        
        func drawResizeHandleRect(rect: NSRect) {
            CGContextSetFillColorWithColor(context, NSColor.whiteColor().CGColor)
            CGContextSetStrokeColorWithColor(context, NSColor.redColor().CGColor)
            CGContextSetLineWidth(context, 1.0)
            
            CGContextAddEllipseInRect(context, rect)
            CGContextDrawPath(context, kCGPathFillStroke)
        }
        
        for shape in drawContents {
            if shape.vertices.count < 2 {
                continue
            }
            
            CGContextSetStrokeColorWithColor(context, shape.lineColor.CGColor)
            CGContextSetFillColorWithColor(context, shape.color.CGColor)
            CGContextSetLineWidth(context, CGFloat(shape.lineWidth))

            if shape.type == DrawShapeType.Line {
                var p1 = shape.vertices[0]
                var p2 = shape.vertices[1]
                
                CGContextMoveToPoint(context, p1.x, p1.y)
                CGContextAddLineToPoint(context, p2.x, p2.y)
                CGContextStrokePath(context)
                
                if shape.selected {
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(p1))
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(p2))
                }
                
            } else if shape.type == .Rect {
                var p1 = shape.vertices[0]
                var p2 = shape.vertices[1]
                
                var rect: CGRect = CGRect(origin:CGPoint(x:min(p1.x, p2.x), y:min(p1.y, p2.y)), size:CGSize(width:fabs(p1.x - p2.x), height:fabs(p1.y - p2.y)))
                
                CGContextFillRect(context, rect)
                CGContextStrokeRect(context, rect)

                if shape.selected {
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.minX, y:rect.minY)))
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.minX, y:rect.maxY)))
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.maxX, y:rect.minY)))
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.maxX, y:rect.maxY)))
                }

            } else if shape.type == .Triangle {
                var p1 = shape.vertices[0]
                var p2 = shape.vertices[1]
                var p3 = shape.vertices[2]
                
                CGContextMoveToPoint(context, p1.x, p1.y)
                CGContextAddLineToPoint(context, p2.x, p2.y)
                CGContextAddLineToPoint(context, p3.x, p3.y)
                CGContextClosePath(context)

                CGContextDrawPath(context, kCGPathFillStroke)
                
                if shape.selected {
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(p1))
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(p2))
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(p3))
                }

            } else if shape.type == .Circle {
                var p1 = shape.vertices[0]
                var p2 = shape.vertices[1]
                
                var rect: CGRect = CGRect(origin:CGPoint(x:min(p1.x, p2.x), y:min(p1.y, p2.y)), size:CGSize(width:fabs(p1.x - p2.x), height:fabs(p1.y - p2.y)))
                
                CGContextAddEllipseInRect(context, rect)
                CGContextDrawPath(context, kCGPathFillStroke)
                
                if shape.selected {
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.minX, y:rect.minY)))
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.minX, y:rect.maxY)))
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.maxX, y:rect.minY)))
                    drawResizeHandleRect(BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.maxX, y:rect.maxY)))
                }
            }
        }
    }
        
    // mouse events
    
    override func mouseDown(event: NSEvent) {
        var p: NSPoint = event.locationInWindow
        p = self.convertPoint(p, fromView:nil)
        p.x = floor(p.x)
        p.y = floor(p.y)
        
        var selectedShape: DrawShape?
        for shape in drawContents.reverse() {
            if shape.containsPoint(p) {
                selectedShape = shape
                break
            }
        }

        if currentShapeTool && currentShapeTool!.resizeHanleContainsPoint(p) {
            // for resizing
            currentShapeTool!.mouseDown(event)
            preVertices = currentShapeTool!.shape.vertices // copy
            
        } else {
            var selectedShape: DrawShape?
            
            for shape in drawContents.reverse() {
                if shape.containsPoint(p) {
                    selectedShape = shape
                    break
                }
            }
            
            if currentShapeTool && currentShapeTool!.shape !== selectedShape {
                currentShapeTool!.shape.selected = false
                self.needsDisplay = true
            }

            if selectedShape {
                // bring to front
                for (index, shape) in enumerate(drawContents) {
                    if shape === selectedShape {
                        var sel = drawContents.removeAtIndex(index)
                        drawContents += sel
                        break
                    }
                }
                
                selectedShape!.selected = true
                currentShapeTool = BaseShapeTool.toolForShape(selectedShape, view:self)

                NSCursor.closedHandCursor().push()

                self.needsDisplay = true

                self.shapeSelectedHandler?(shape:currentShapeTool!.shape)
                preVertices = currentShapeTool!.shape.vertices

            } else {
                // create new one
                var shape = DrawShape(drawType)
                currentShapeTool = BaseShapeTool.toolForShape(shape, view:self)
                
                drawContents += shape
                createdShape = true
            }
            
            currentShapeTool!.mouseDown(event)
        }
    }
    
    override func mouseDragged(event: NSEvent) {
        currentShapeTool?.mouseDragged(event)
        self.needsDisplay = true
    }
    
    override func mouseUp(event: NSEvent) {
        NSCursor.pop()
        currentShapeTool?.mouseUp(event)
        
        if let shape = currentShapeTool?.shape {
            if shape.vertices.count < 2 {
                // just click
                drawContents.removeLast()
                currentShapeTool = nil
                
            } else {
                if !shape.selected {
                    self.shapeSelectedHandler?(shape:shape)
                }
                shape.selected = true
                
                if createdShape {
                    self.undoManager.prepareWithInvocationTarget(self).removeShapeForUndo([shape])
                }
                
                if preVertices && shape.vertices != preVertices! {
                    // arguments of invocation method must inherit nsobject...
                    let array:Array<NSValue> = preVertices!.map({ point in return NSValue(point:point) })
                    var dict:NSDictionary = ["shape":shape, "vertices": array]
                    self.undoManager.prepareWithInvocationTarget(self).updateShapeForUndo(dict)
                }
            }
        }
        
        createdShape = false
        self.needsDisplay = true
    }

    override func mouseMoved(event: NSEvent) {
        var p: NSPoint = event.locationInWindow
        p = self.convertPoint(p, fromView:nil)
        
        if let shape = currentShapeTool?.shape {
            if shape.selected {
                if currentShapeTool!.resizeHanleContainsPoint(p) {
                    // for resizing
                    if NSCursor.currentSystemCursor() != NSCursor.crosshairCursor() {
                        NSCursor.pop()
                    }
                    NSCursor.crosshairCursor().push()

                } else if shape.containsPoint(p) {
                    // for move
                    if NSCursor.currentSystemCursor() != NSCursor.openHandCursor() {
                        NSCursor.pop()
                    }
                    NSCursor.openHandCursor().push()

                } else {
                    NSCursor.pop()
                }
            } else {
                NSCursor.pop()
            }
            
        } else {
            NSCursor.pop()
        }
    }
    
    override func magnifyWithEvent(event: NSEvent!) {
        currentShapeTool?.magnifyWithEvent(event)
        self.needsDisplay = true
    }
    
    override var acceptsFirstResponder: Bool {
    return true
    }

    override func validateMenuItem(menuItem: NSMenuItem!) -> Bool {
        if menuItem.action == "copy:" ||  menuItem.action == "delete:" {
            return currentShapeTool?.shape != nil
            
        } else if menuItem.action == "paste:" {
            return copiedShape != nil
        }
        
        return true
    }
    
    func copy(sender: AnyObject) {
        if let shape = currentShapeTool?.shape {
            copiedShape = shape.copy()
            pasteCount = 0
        }
    }
    
    func paste(sender: AnyObject) {
        if let pasted = copiedShape?.copy() {
            let shift = CGFloat(++pasteCount * 10)
            var updatedVerts = pasted.vertices.map{ (point) -> NSPoint in
                return NSPoint(x:point.x + shift, y:point.y - shift)
            }
            pasted.vertices = updatedVerts
            
            if let preShape = currentShapeTool?.shape {
                preShape.selected = false
                currentShapeTool = nil
            }
            
            currentShapeTool = BaseShapeTool.toolForShape(pasted, view: self)
            pasted.selected = true
            
            drawContents += pasted

            self.undoManager.prepareWithInvocationTarget(self).removeShapeForUndo([pasted])
            
            self.needsDisplay = true
        }
    }
    
    func delete(sender: AnyObject) {
        if let shape = currentShapeTool?.shape {
            for (index, s) in enumerate(drawContents) {
                if s === shape {
                    let removed = drawContents.removeAtIndex(index)
                    removed.selected = false
                    self.undoManager.prepareWithInvocationTarget(self).addShapeForUndo([removed])
                    break
                }
            }
            // then clear
            currentShapeTool = nil
            self.needsDisplay = true
        }
    }
    
    // for undo/redo
    
    func updateShapeForUndo(shapeInfo:NSDictionary) {
        let shape = shapeInfo["shape"] as DrawShape
        let vert = shapeInfo["vertices"] as Array<NSValue>
        let convertedVert:Array<NSPoint> = vert.map({ value in value.pointValue })
        
        // for redo
        let redoArray:Array<NSValue> = shape.vertices.map({ point in return NSValue(point:point) })
        self.undoManager.prepareWithInvocationTarget(self).updateShapeForUndo([ "shape":shape, "vertices":redoArray ])
        
        shape.vertices = convertedVert
        self.needsDisplay = true
    }
    
    func addShapeForUndo(shapes:NSArray) {
        if shapes.count > 0 {
            drawContents += (shapes as Array<DrawShape>)
            self.needsDisplay = true
        
            // for redo
            self.undoManager.prepareWithInvocationTarget(self).removeShapeForUndo(shapes)
        }
    }
    
    func removeShapeForUndo(shapes:NSArray) {
        var indexes = [Int]()
        for (index, s) in enumerate(drawContents) {
            for remove in shapes as [DrawShape] {
                if s == remove {
                    indexes += index
                    remove.selected = false
                    break
                }
            }
        }
        
        if indexes.count > 0 {
            for idx in indexes {
                drawContents.removeAtIndex(idx)
            }
            
            self.needsDisplay = true
            
            if drawContents.count == 0 {
                currentShapeTool = nil
            }
        }
        
        // for redo
        self.undoManager.prepareWithInvocationTarget(self).addShapeForUndo(shapes)
    
    }
}
