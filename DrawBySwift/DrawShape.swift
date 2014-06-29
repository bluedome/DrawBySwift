//
//  DrawShape.swift
//  DrawBySwift
//

import Cocoa

enum DrawShapeType: Int {
    case Line = 0
    case Rect
    case Triangle
    case Circle

    var description: String {
        switch self {
        case .Line:
            return "Line"
        case .Rect:
            return "Rectangle"
        case .Triangle:
            return "Triangle"
        case .Circle:
            return "Circle"
        }
    }
}

class DrawShape {
    let type: DrawShapeType
    
    var vertices: Array<NSPoint> = []
    var lineColor: NSColor = NSColor.blackColor()
    var color: NSColor = NSColor.whiteColor()
    var lineWidth = 1.0
    
    var selected: Bool = false
    
    var presentedRect: CGRect {
        if vertices.count < 2 {
            return CGRectZero
        }
        
        var p1 = vertices[0]
        var p2 = vertices[1]

        return CGRect(origin:CGPoint(x:min(p1.x, p2.x), y:min(p1.y, p2.y)), size:CGSize(width:fabs(p1.x - p2.x), height:fabs(p1.y - p2.y)))
    }
    
    init(_ type: DrawShapeType) {
        self.type = type
        
        switch (type) {
        case .Line:
            lineWidth = 2.0
        case .Rect:
            color = NSColor.orangeColor()
        case .Triangle:
            color = NSColor.cyanColor()
        case .Circle:
            color = NSColor.greenColor()
        }
    }
    
    func copy() -> DrawShape {
        let copied = DrawShape(self.type)
        copied.lineWidth = self.lineWidth
        copied.color = self.color.copy() as NSColor
        copied.lineColor = self.lineColor.copy() as NSColor
        copied.vertices = self.vertices.copy()
        
        return copied
    }

    func containsPoint(point: NSPoint) -> Bool {
        
        if (type == DrawShapeType.Line) {

            if vertices.count != 2 {
                return false
            }
            
            var p1 = vertices[0]
            var p2 = vertices[1]
            
            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            
            let a = dx*dx + dy*dy
            let b = dx*(p1.x - point.x) + dy*(p1.y - point.y)
            var t = -b/a
            t = t < 0 ? 0 : t
            t = t > 1 ? 1 : t
            
            let cx = t*dx + p1.x
            let cy = t*dy + p1.y
            
            let distance = ((cx - point.x) * (cx - point.x) + (cy - point.y) * (cy - point.y))
//            NSLog("dist=%f", distance)
            
            return distance < 50
            
        } else if (type == .Rect) {
            return presentedRect.contains(point)
            
        } else if (type == .Triangle) {

            if vertices.count < 2 { return false }

            var bezierPath = NSBezierPath()
            bezierPath.moveToPoint(vertices[0])
            bezierPath.lineToPoint(vertices[1])
            bezierPath.lineToPoint(vertices[2])
            bezierPath.closePath()
            
            return bezierPath.containsPoint(point)
            
        } else if (type == .Circle) {
            var bezierPath = NSBezierPath(ovalInRect:presentedRect)
            return bezierPath.containsPoint(point)
        }
        
        return false
    }
}

func ==(lhs:DrawShape, rhs:DrawShape) -> Bool {
    return (lhs.type == rhs.type) && (lhs.vertices == rhs.vertices) && (lhs.color == rhs.color) && (lhs.lineWidth == rhs.lineWidth) && (lhs.lineColor == rhs.lineColor)
}

