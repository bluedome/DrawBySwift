//
//  DrawShapeTool.swift
//  DrawBySwift
//

import Cocoa

class BaseShapeTool {
    class func toolForShape(shape: DrawShape!, view: NSView!) -> BaseShapeTool {
        switch (shape.type) {
        case .Line:
            return LineShapeTool(shape:shape, view:view)
        case .Rect:
            return RectShapeTool(shape:shape, view:view)
        case .Triangle:
            return TriangleShapeTool(shape:shape, view:view)
        case .Circle:
            return CircleShapeTool(shape:shape, view:view)
        }
    }
    
    class var handleSize: CGFloat {
    return 10
    }
    class func resizeHandleRectForPoint(point: NSPoint) -> CGRect {
        return CGRect(x: point.x - handleSize/2, y: point.y - handleSize/2, width: handleSize, height: handleSize)
    }

    class var minimumSize: CGFloat {
    return 10
    }
    
    var associatedView: NSView
    var shape: DrawShape
    
    init(shape: DrawShape, view: NSView) {
        associatedView = view
        self.shape = shape
    }
    
    func mouseDown(event: NSEvent) {
        assert(false, "subclass must implement")
    }
    
    func mouseDragged(event: NSEvent) {
        assert(false, "subclass must implement")
    }
    
    func mouseUp(event: NSEvent) {
        assert(false, "subclass must implement")
    }
    
    func magnifyWithEvent(event: NSEvent) {
        if shape.type == DrawShapeType.Triangle || shape.vertices.count < 2 {
            return
        }
        
        var p1 = shape.vertices[0]
        var p2 = shape.vertices[1]
        
        if p1 == p2 {
            return
        }
        
        var a = p2.y - p1.y
        var b = p1.x - p2.x
        var c = p2.x*p1.y - p1.x*p2.y
        
        var coefficient = 15.0 * event.magnification
        if a == 0 {
            if p1.x <= p2.x {
                p1.x -= coefficient
                p2.x += coefficient
            } else {
                p1.x += coefficient
                p2.x -= coefficient
            }
            
        } else if b == 0 {
            if p1.y <= p2.y {
                p1.y -= coefficient
                p2.y += coefficient
            } else {
                p1.y += coefficient
                p2.y -= coefficient
            }
            
        } else {
            if p1.x <= p2.x {
                p1.x -= coefficient
                p2.x += coefficient
            } else {
                p1.x += coefficient
                p2.x -= coefficient
            }
            
            p1.y = -(a*p1.x + c)/b
            p2.y = -(a*p2.x + c)/b
        }
        
        shape.vertices[0] = p1
        shape.vertices[1] = p2
        
    }
    
    func resizeHanleContainsPoint(point: NSPoint) -> Bool {
        assert(false, "subclass must implement")
        return false
    }

}

class LineShapeTool : BaseShapeTool {
    var resizing = false
    var dragged = false
    var resizingIndex = 0
    var distance1 = CGSizeZero
    var distance2 = CGSizeZero
    
    func indexOfDraggedPoint(point: NSPoint) -> Int {
        for (index, p) in enumerate(shape.vertices) {
            let rect = BaseShapeTool.resizeHandleRectForPoint(p)
            if rect.contains(point) {
                return index
            }
        }
        return -1
    }
    
    override func resizeHanleContainsPoint(point: NSPoint) -> Bool {
        return indexOfDraggedPoint(point) >= 0
    }
    
    override func mouseDown(event: NSEvent) {
        var p: NSPoint = event.locationInWindow
        p = associatedView.convertPoint(p, fromView:nil)
        
        resizingIndex = indexOfDraggedPoint(p)
        if resizingIndex >= 0 {
            // for resizing
            resizing = true
            
        } else if shape.containsPoint(p) {
            // move
            dragged = true
            
            let p1 = shape.vertices[0]
            let p2 = shape.vertices[1]
            
            p.x = floor(p.x)
            p.y = floor(p.y)
            distance1 = CGSize(width:p.x - p1.x, height:p.y - p1.y)
            distance2 = CGSize(width:p.x - p2.x, height:p.y - p2.y)
            
        } else {
            p.x = floor(p.x)
            p.y = floor(p.y)
            shape.vertices = [p]
        }
    }
    
    override func mouseDragged(event: NSEvent) {
        var p: NSPoint = event.locationInWindow
        p = associatedView.convertPoint(p, fromView:nil)
        p.x = floor(p.x)
        p.y = floor(p.y)

        if resizing && resizingIndex >= 0{
            shape.vertices[resizingIndex] = p
            
        } else if dragged {
            shape.vertices[0].x = p.x - distance1.width
            shape.vertices[0].y = p.y - distance1.height
            
            shape.vertices[1].x = p.x - distance2.width
            shape.vertices[1].y = p.y - distance2.height
            
        } else {
            // creating
            if shape.vertices.count < 2 {
                shape.vertices += p
            } else {
                shape.vertices[1] = p
            }
        }
    }
    
    override func mouseUp(event: NSEvent) {
        resizing = false
        dragged = false
    }

}

class RectShapeTool : BaseShapeTool {
    var dragged = false
    var resizeCorner = RectCorner.None
    var distance1 = CGSizeZero
    var distance2 = CGSizeZero

    enum RectCorner {
        case LowerLeft
        case LowerRight
        case UpperLeft
        case UpperRight
        case None
    }
    
    func resizeCornerForPoint(point: NSPoint) -> RectCorner {
        let rect = shape.presentedRect
        
        if BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.minX, y:rect.minY)).contains(point) {
            return .LowerLeft
            
        } else if BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.minX, y:rect.maxY)).contains(point) {
            return .UpperLeft
            
        } else if BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.maxX, y:rect.minY)).contains(point) {
            return .LowerRight
            
        } else if BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.maxX, y:rect.maxY)).contains(point) {
            return .UpperRight
        }

        return .None
    }
    
    override func resizeHanleContainsPoint(point: NSPoint) -> Bool {
        return resizeCornerForPoint(point) != RectCorner.None
    }

    override func mouseDown(event: NSEvent) {
        var p: NSPoint = event.locationInWindow
        p = associatedView.convertPoint(p, fromView:nil)
        
        resizeCorner = resizeCornerForPoint(p)
        if resizeCorner != RectCorner.None {
            // for resizing
            
        } else if shape.containsPoint(p) {
            // move
            dragged = true
            
            let p1 = shape.vertices[0]
            let p2 = shape.vertices[1]
            
            p.x = floor(p.x)
            p.y = floor(p.y)
            distance1 = CGSize(width:p.x - p1.x, height:p.y - p1.y)
            distance2 = CGSize(width:p.x - p2.x, height:p.y - p2.y)
            
        } else {
            p.x = floor(p.x)
            p.y = floor(p.y)
            shape.vertices = [p]
        }
    }
    
    override func mouseDragged(event: NSEvent) {
        var p: NSPoint = event.locationInWindow
        p = associatedView.convertPoint(p, fromView:nil)
        p.x = floor(p.x)
        p.y = floor(p.y)
        
        if resizeCorner != RectCorner.None {
            var rect = shape.presentedRect
            
            if resizeCorner == .LowerLeft {
                let maxX = rect.maxX
                let maxY = rect.maxY
                
                rect.size.width = maxX - p.x
                rect.size.height = maxY - p.y
                rect.origin = p
                
                if rect.size.width < BaseShapeTool.minimumSize {
                    rect.origin.x = maxX - BaseShapeTool.minimumSize
                    rect.size.width = BaseShapeTool.minimumSize
                }
                
                if rect.size.height < BaseShapeTool.minimumSize {
                    rect.origin.y = maxY - BaseShapeTool.minimumSize
                    rect.size.height = BaseShapeTool.minimumSize
                }
                
            } else if resizeCorner == .LowerRight {
                let maxX = rect.maxX
                let maxY = rect.maxY

                rect.origin.y = p.y
                rect.size.width = p.x - rect.origin.x
                rect.size.height = maxY - p.y
                
                if rect.size.width < BaseShapeTool.minimumSize {
                    rect.size.width = BaseShapeTool.minimumSize
                }
                if rect.size.height < BaseShapeTool.minimumSize {
                    rect.size.height = BaseShapeTool.minimumSize
                    rect.origin.y = maxY - BaseShapeTool.minimumSize
                }
                
            } else if resizeCorner == .UpperLeft {
                let maxX = rect.maxX
                let maxY = rect.maxY

                rect.origin.x = p.x
                rect.size.width = maxX - p.x
                rect.size.height = p.y - rect.origin.y
                
                if rect.size.width < BaseShapeTool.minimumSize {
                    rect.size.width = BaseShapeTool.minimumSize
                    rect.origin.x = maxX - BaseShapeTool.minimumSize
                }
                if rect.size.height < BaseShapeTool.minimumSize {
                    rect.size.height = BaseShapeTool.minimumSize
                }

            } else if resizeCorner == .UpperRight {
                rect.size.width = p.x - rect.origin.x
                rect.size.height = p.y - rect.origin.y
                
                if rect.size.width < BaseShapeTool.minimumSize {
                    rect.size.width = BaseShapeTool.minimumSize
                }
                if rect.size.height < BaseShapeTool.minimumSize {
                    rect.size.height = BaseShapeTool.minimumSize
                }
            }
            
            shape.vertices[0] = rect.origin
            shape.vertices[1] = NSPoint(x:rect.maxX, y:rect.maxY)
            
        } else if dragged {
            shape.vertices[0].x = p.x - distance1.width
            shape.vertices[0].y = p.y - distance1.height
            
            shape.vertices[1].x = p.x - distance2.width
            shape.vertices[1].y = p.y - distance2.height
            
        } else {
            // creating
            if shape.vertices.count < 2 {
                shape.vertices += p
            } else {
                shape.vertices[1] = p
            }
        }
    }
    
    override func mouseUp(event: NSEvent) {
        if shape.vertices.count > 1 {
            var rect = shape.presentedRect
            if rect.width < BaseShapeTool.minimumSize || rect.height < BaseShapeTool.minimumSize {
                // fix
                rect.size.width = max(BaseShapeTool.minimumSize, rect.width)
                rect.size.height = max(BaseShapeTool.minimumSize, rect.height)
                
                shape.vertices = [ rect.origin, NSPoint(x:rect.maxX, y:rect.maxY) ]
            }
        }
        
        dragged = false
    }
}

class TriangleShapeTool : BaseShapeTool {
    var dragged = false
    var resizingIndex = 0
    var distance1 = CGSizeZero
    var distance2 = CGSizeZero
    var distance3 = CGSizeZero
    var startPoint = NSZeroPoint
    
    func indexOfDraggedPoint(point: NSPoint) -> Int {
        for (index, p) in enumerate(shape.vertices) {
            let rect = BaseShapeTool.resizeHandleRectForPoint(p)
            if rect.contains(point) {
                return index
            }
        }
        return -1
    }
    
    override func resizeHanleContainsPoint(point: NSPoint) -> Bool {
        return indexOfDraggedPoint(point) >= 0
    }

    override func mouseDown(event: NSEvent) {
        var p: NSPoint = event.locationInWindow
        p = associatedView.convertPoint(p, fromView:nil)
        
        resizingIndex = indexOfDraggedPoint(p)
        if resizingIndex < 0 {
            if shape.containsPoint(p) {
                p.x = floor(p.x)
                p.y = floor(p.y)

                // move
                dragged = true
                
                let p1 = shape.vertices[0]
                let p2 = shape.vertices[1]
                let p3 = shape.vertices[2]
                
                distance1 = CGSize(width:p.x - p1.x, height:p.y - p1.y)
                distance2 = CGSize(width:p.x - p2.x, height:p.y - p2.y)
                distance3 = CGSize(width:p.x - p3.x, height:p.y - p3.y)
                
            } else {
                p.x = floor(p.x)
                p.y = floor(p.y)

                startPoint = p
            }
        }
    }
    
    override func mouseDragged(event: NSEvent) {
        var p: NSPoint = event.locationInWindow
        p = associatedView.convertPoint(p, fromView:nil)
        p.x = floor(p.x)
        p.y = floor(p.y)
        
        if resizingIndex >= 0{
            shape.vertices[resizingIndex] = p
            
        } else if dragged {
            shape.vertices[0].x = p.x - distance1.width
            shape.vertices[0].y = p.y - distance1.height
            
            shape.vertices[1].x = p.x - distance2.width
            shape.vertices[1].y = p.y - distance2.height
            
            shape.vertices[2].x = p.x - distance3.width
            shape.vertices[2].y = p.y - distance3.height
            
        } else {
            // creating
            var rect = NSRect(x:min(startPoint.x, p.x), y:min(startPoint.y, p.y), width:fabs(startPoint.x - p.x), height:fabs(startPoint.y - p.y))
            shape.vertices = [rect.origin, NSPoint(x:rect.maxX, y:rect.minY), NSPoint(x:rect.midX, y:rect.maxY)]
            
        }
    }
    
    override func mouseUp(event: NSEvent) {
        if shape.vertices.count == 3 {            
            var p: NSPoint = event.locationInWindow
            p = associatedView.convertPoint(p, fromView:nil)
            p.x = floor(p.x)
            p.y = floor(p.y)

            var rect = NSRect(x:min(startPoint.x, p.x), y:min(startPoint.y, p.y), width:fabs(startPoint.x - p.x), height:fabs(startPoint.y - p.y))
            if rect.width < BaseShapeTool.minimumSize || rect.height < BaseShapeTool.minimumSize {
                // fix
                rect.size.width = max(BaseShapeTool.minimumSize, rect.width)
                rect.size.height = max(BaseShapeTool.minimumSize, rect.height)
                
                shape.vertices = [rect.origin, NSPoint(x:rect.maxX, y:rect.minY), NSPoint(x:rect.midX, y:rect.maxY)]
            }
        }

        dragged = false
        startPoint = NSPoint.zeroPoint
    }
}

class CircleShapeTool : BaseShapeTool {
    var dragged = false
    var resizeCorner = RectCorner.None
    var distance1 = CGSizeZero
    var distance2 = CGSizeZero
    
    enum RectCorner {
        case LowerLeft
        case LowerRight
        case UpperLeft
        case UpperRight
        case None
    }
    
    func resizeCornerForPoint(point: NSPoint) -> RectCorner {
        let rect = shape.presentedRect
        
        if BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.minX, y:rect.minY)).contains(point) {
            return .LowerLeft
            
        } else if BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.minX, y:rect.maxY)).contains(point) {
            return .UpperLeft
            
        } else if BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.maxX, y:rect.minY)).contains(point) {
            return .LowerRight
            
        } else if BaseShapeTool.resizeHandleRectForPoint(NSPoint(x:rect.maxX, y:rect.maxY)).contains(point) {
            
            return .UpperRight
        }
        
        return .None
    }
    
    override func resizeHanleContainsPoint(point: NSPoint) -> Bool {
        return resizeCornerForPoint(point) != RectCorner.None
    }
    
    override func mouseDown(event: NSEvent) {
        var p: NSPoint = event.locationInWindow
        p = associatedView.convertPoint(p, fromView:nil)
        
        resizeCorner = resizeCornerForPoint(p)
        if resizeCorner != RectCorner.None {
            // for resizing
            
        } else if shape.containsPoint(p) {
            // move
            dragged = true
            
            let p1 = shape.vertices[0]
            let p2 = shape.vertices[1]
            
            p.x = floor(p.x)
            p.y = floor(p.y)
            distance1 = CGSize(width:p.x - p1.x, height:p.y - p1.y)
            distance2 = CGSize(width:p.x - p2.x, height:p.y - p2.y)
            
        } else {
            p.x = floor(p.x)
            p.y = floor(p.y)
            shape.vertices = [p]
        }
    }
    
    override func mouseDragged(event: NSEvent) {
        var p: NSPoint = event.locationInWindow
        p = associatedView.convertPoint(p, fromView:nil)
        p.x = floor(p.x)
        p.y = floor(p.y)
        
        if resizeCorner != RectCorner.None {
            var rect = shape.presentedRect
            
            if resizeCorner == .LowerLeft {
                let maxX = rect.maxX
                let maxY = rect.maxY
                
                rect.size.width = maxX - p.x
                rect.size.height = maxY - p.y
                rect.origin = p
                
                if rect.size.width < BaseShapeTool.minimumSize {
                    rect.origin.x = maxX - BaseShapeTool.minimumSize
                    rect.size.width = BaseShapeTool.minimumSize
                }
                
                if rect.size.height < BaseShapeTool.minimumSize {
                    rect.origin.y = maxY - BaseShapeTool.minimumSize
                    rect.size.height = BaseShapeTool.minimumSize
                }
                
            } else if resizeCorner == .LowerRight {
                let maxX = rect.maxX
                let maxY = rect.maxY
                
                rect.origin.y = p.y
                rect.size.width = p.x - rect.origin.x
                rect.size.height = maxY - p.y
                
                if rect.size.width < BaseShapeTool.minimumSize {
                    rect.size.width = BaseShapeTool.minimumSize
                }
                if rect.size.height < BaseShapeTool.minimumSize {
                    rect.size.height = BaseShapeTool.minimumSize
                    rect.origin.y = maxY - BaseShapeTool.minimumSize
                }
                
            } else if resizeCorner == .UpperLeft {
                let maxX = rect.maxX
                let maxY = rect.maxY
                
                rect.origin.x = p.x
                rect.size.width = maxX - p.x
                rect.size.height = p.y - rect.origin.y
                
                if rect.size.width < BaseShapeTool.minimumSize {
                    rect.size.width = BaseShapeTool.minimumSize
                    rect.origin.x = maxX - BaseShapeTool.minimumSize
                }
                if rect.size.height < BaseShapeTool.minimumSize {
                    rect.size.height = BaseShapeTool.minimumSize
                }
                
            } else if resizeCorner == .UpperRight {
                rect.size.width = p.x - rect.origin.x
                rect.size.height = p.y - rect.origin.y
                
                if rect.size.width < BaseShapeTool.minimumSize {
                    rect.size.width = BaseShapeTool.minimumSize
                }
                if rect.size.height < BaseShapeTool.minimumSize {
                    rect.size.height = BaseShapeTool.minimumSize
                }
            }
            
            shape.vertices[0] = rect.origin
            shape.vertices[1] = NSPoint(x:rect.maxX, y:rect.maxY)
            
        } else if dragged {
            shape.vertices[0].x = p.x - distance1.width
            shape.vertices[0].y = p.y - distance1.height
            
            shape.vertices[1].x = p.x - distance2.width
            shape.vertices[1].y = p.y - distance2.height
            
        } else {
            // creating
            if shape.vertices.count < 2 {
                shape.vertices += p
            } else {
                shape.vertices[1] = p
            }
        }
    }
    
    override func mouseUp(event: NSEvent) {
        if shape.vertices.count > 1 {
            var rect = shape.presentedRect
            if rect.width < BaseShapeTool.minimumSize || rect.height < BaseShapeTool.minimumSize {
                // fix
                rect.size.width = max(BaseShapeTool.minimumSize, rect.width)
                rect.size.height = max(BaseShapeTool.minimumSize, rect.height)
                
                shape.vertices = [ rect.origin, NSPoint(x:rect.maxX, y:rect.maxY) ]
            }
        }
        
        dragged = false
    }
}

