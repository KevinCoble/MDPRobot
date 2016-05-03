//
//  WorldView.swift
//  MDPRobot
//
//  Created by Kevin Coble on 3/30/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa
import Accelerate
import AIToolbox

enum WorldItemType {
    case None
    case Goal
    case Pit
    case Obstacle
    case Robot
}

enum RobotType {
    case TwoState       //  State is only position, action is N, W, S, E
    case ThreeState     //  State is position and angle, action is forward, backwards, rotate CW, rotate CCW
}

enum WorldMode {
    case Edit
    case Run
    case View
}

class WorldView: NSView {
    
    //  Mode
    var mode = WorldMode.Edit
    
    //  Goals
    let goalRadius : CGFloat = 4.0
    var goalEnabled = [true, false, false, false]
    var goalPosition = [CGPoint(x: 80, y: 80),
                        CGPoint(x: 20, y: 80),
                        CGPoint(x: 80, y: 20),
                        CGPoint(x: 20, y: 20)]
    
    //  Pits
    let pitRadius : CGFloat = 4.0
    var pitEnabled = [true, false, false, false]
    var pitPosition =  [CGPoint(x: 30, y: 30),
                        CGPoint(x: 30, y: 70),
                        CGPoint(x: 70, y: 30),
                        CGPoint(x: 70, y: 70)]
    
    //  Obstacles
    let obstacleRadius : CGFloat = 4.0
    var obstacleEnabled = [true, false, false, false, false, false, false, false, false, false]
    var obstaclePosition =  [CGPoint(x: 10, y: 10),
                             CGPoint(x: 10, y: 50),
                             CGPoint(x: 10, y: 90),
                             CGPoint(x: 50, y: 10),
                             CGPoint(x: 50, y: 50),
                             CGPoint(x: 50, y: 90),
                             CGPoint(x: 90, y: 10),
                             CGPoint(x: 90, y: 50),
                             CGPoint(x: 90, y: 90),
                             CGPoint(x: 75, y: 50)]
    
    //  Robot
    var robotType = RobotType.TwoState
    let robotRadius : CGFloat = 4.0
    var robotPosition = CGPoint(x: 0, y: 0)
    var robotAngle : CGFloat = 0.0
    let robotSpeed : CGFloat = 25.0           //  4 seconds to cross
    let robotTurnSpeed : CGFloat = 180.0      //  2 seconds to turn around
    
    //  Flags
    var lastActionCausedStall = false       //  Flag indicating the last action resulted in no movement
    
    //  Edit state
    var dragItemType = WorldItemType.None
    var dragItemIndex = 0
    var dragItemLastLoc = CGPointZero
    
    //  MDP and fit model
    let markov = MDP(states: 0, actions: 4, discount: 0.98) //  Leave continuous state parameters at default
    var lrmodel = LinearRegressionModel(inputSize: 2, outputSize: 1, polygonOrder: 1)
    
    func changeModel(polygonOrder: Int, withCrossTerms: Bool)
    {
        if (robotType == .TwoState) {
            lrmodel = LinearRegressionModel(inputSize: 2, outputSize: 1, polygonOrder: polygonOrder, includeCrossTerms: withCrossTerms)
        }
        else {
            lrmodel = LinearRegressionModel(inputSize: 3, outputSize: 1, polygonOrder: polygonOrder, includeCrossTerms: withCrossTerms)
        }
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        //  Calculate the drawing scale
        let xscale : CGFloat = bounds.size.width / (100.0 + 2.0 * robotRadius)
        let yscale : CGFloat = bounds.size.height / (100.0 + 2.0 * robotRadius)
        
        //  draw the background
        NSColor.whiteColor().setFill()
        NSRectFill(bounds)
        
        if (mode == .View && robotType == .TwoState) {
            showExpectedReward(20, xscale : xscale, yscale : yscale)
        }
        
        //  Set the label text attributes
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = 6.0
        paraStyle.alignment = NSTextAlignment.Center
        let attributes = [
            NSForegroundColorAttributeName: NSColor.whiteColor(),
            NSParagraphStyleAttributeName: paraStyle,
            //NSTextAlignment: textalign,
            NSFontAttributeName: NSFont(name: "Helvetica Neue", size: 12)!
        ]
        
        //  Draw each goal
        let goalColor = NSColor.greenColor()
        goalColor.set()
        for index in 0..<goalEnabled.count {
            if (goalEnabled[index]) {
                var circleRect = NSMakeRect((goalPosition[index].x - goalRadius + robotRadius) * xscale,
                                            (goalPosition[index].y - goalRadius + robotRadius) * yscale,
                                            2.0 * goalRadius * xscale, 2.0 * goalRadius * yscale)
                let cPath: NSBezierPath = NSBezierPath(ovalInRect: circleRect)
                goalColor.set()
                cPath.fill()
                if (mode == .Edit) {
                    let str = "\(index+1)"
                    circleRect.size.height -= 5.0
                    str.drawInRect(circleRect, withAttributes: attributes)
                }
            }
        }
        
        //  Draw each pit
        let pitColor = NSColor.blackColor()
        for index in 0..<pitEnabled.count {
            if (pitEnabled[index]) {
                var circleRect = NSMakeRect((pitPosition[index].x - pitRadius + robotRadius) * xscale,
                                            (pitPosition[index].y - pitRadius + robotRadius) * yscale,
                                            2.0 * pitRadius * xscale, 2.0 * pitRadius * yscale)
                let cPath: NSBezierPath = NSBezierPath(ovalInRect: circleRect)
                pitColor.set()
                cPath.fill()
                if (mode == .Edit) {
                    let str = "\(index+1)"
                    circleRect.size.height -= 5.0
                    str.drawInRect(circleRect, withAttributes: attributes)
                }
            }
        }
        
        //  Draw each obstacle
        let obstacleColor = NSColor.darkGrayColor()
        for index in 0..<obstacleEnabled.count {
            if (obstacleEnabled[index]) {
                var circleRect = NSMakeRect((obstaclePosition[index].x - obstacleRadius + robotRadius) * xscale,
                                            (obstaclePosition[index].y - obstacleRadius + robotRadius) * yscale,
                                            2.0 * obstacleRadius * xscale, 2.0 * obstacleRadius * yscale)
                let cPath: NSBezierPath = NSBezierPath(ovalInRect: circleRect)
                obstacleColor.set()
                cPath.fill()
                if (mode == .Edit) {
                    let str = "\(index+1)"
                    circleRect.size.height -= 5.0
                    str.drawInRect(circleRect, withAttributes: attributes)
                }
            }
        }
        
        //  Show the actions if requested
        if (mode == .View) {
            if (robotType == .TwoState) {
                for x in 0...20 {
                    for y in 0...20 {
                        showActionsTwoState(CGPoint(x: 5 * x, y: 5 * y), xscale: xscale, yscale: yscale)
                    }
                }
            }
            else {
                for x in 0...10 {
                    for y in 0...10 {
                        showActionsThreeState(CGPoint(x: 10 * x, y: 10 * y), xscale: xscale, yscale: yscale)
                    }
                }
            }
        }
        
        //  Draw the robot
        let xform = NSAffineTransform()
        xform.translateXBy((robotPosition.x + robotRadius) * xscale, yBy: (robotPosition.y + robotRadius) * yscale)
        xform.rotateByDegrees(robotAngle)
        xform.concat()
        let robotColor = NSColor.blueColor()
        robotColor.set()
        let circleRect = NSMakeRect(-robotRadius * xscale,
                                    -robotRadius * yscale,
                                    2.0 * robotRadius * xscale, 2.0 * robotRadius * yscale)
        let cPath: NSBezierPath = NSBezierPath(ovalInRect: circleRect)
        cPath.fill()
        if (robotType == .ThreeState) {
            let robotArrowColor = NSColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0)
            robotArrowColor.set()
            let arrowPath = NSBezierPath()
            arrowPath.moveToPoint(NSMakePoint(0.0, robotRadius * yscale))
            arrowPath.lineToPoint(NSMakePoint(-0.5 * robotRadius * xscale, 0.0))
            arrowPath.lineToPoint(NSMakePoint(0.5 * robotRadius * xscale, 0.0))
            arrowPath.closePath()
            arrowPath.fill()
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        //  Convert the location to a world-centric version
        var loc = convertPoint(theEvent.locationInWindow, toView: nil)
        loc.y -= 100.0;      //!!  Don't know why coordinate conversion isn't working!
        let xloc : CGFloat = (loc.x / bounds.size.width) * (100.0 + 2.0 * robotRadius) - robotRadius
        let yloc : CGFloat = (loc.y / bounds.size.height) * (100.0 + 2.0 * robotRadius) - robotRadius
        dragItemLastLoc.x = xloc
        dragItemLastLoc.y = yloc
        dragItemType = WorldItemType.None
        
        //  See if the click is on the robot
        var distance : CGFloat
        distance = xloc - robotPosition.x
        distance *= distance
        distance += (yloc - robotPosition.y) * (yloc - robotPosition.y)
        distance = sqrt(distance)
        if (distance < robotRadius) {
            dragItemType = WorldItemType.Robot
            dragItemIndex = 0
            return
        }
       
        //  See if the click is on an obstacle
        for index in 0..<obstacleEnabled.count {
            if (obstacleEnabled[index]) {
                distance = xloc - obstaclePosition[index].x
                distance *= distance
                distance += (yloc - obstaclePosition[index].y) * (yloc - obstaclePosition[index].y)
                distance = sqrt(distance)
                if (distance < obstacleRadius) {
                    dragItemType = WorldItemType.Obstacle
                    dragItemIndex = index
                    return
                }
            }
        }
        
        //  See if the click is on a pit
        for index in 0..<pitEnabled.count {
            if (pitEnabled[index]) {
                distance = xloc - pitPosition[index].x
                distance *= distance
                distance += (yloc - pitPosition[index].y) * (yloc - pitPosition[index].y)
                distance = sqrt(distance)
                if (distance < pitRadius) {
                    dragItemType = WorldItemType.Pit
                    dragItemIndex = index
                    return
                }
            }
        }
        
        //  See if the click is on a goal
        for index in 0..<goalEnabled.count {
            if (goalEnabled[index]) {
                distance = xloc - goalPosition[index].x
                distance *= distance
                distance += (yloc - goalPosition[index].y) * (yloc - goalPosition[index].y)
                distance = sqrt(distance)
                if (distance < goalRadius) {
                    dragItemType = WorldItemType.Goal
                    dragItemIndex = index
                    return
                }
            }
        }
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        //  Convert the location to a world-centric version
        var loc = convertPoint(theEvent.locationInWindow, toView: nil)
        loc.y -= 100.0;      //!!  Don't know why coordinate conversion isn't working!
        let xloc : CGFloat = (loc.x / bounds.size.width) * (100.0 + 2.0 * robotRadius) - robotRadius
        let yloc : CGFloat = (loc.y / bounds.size.height) * (100.0 + 2.0 * robotRadius) - robotRadius
        
        //  Update any dragged item
        switch (dragItemType) {
        case WorldItemType.None:
            return
        case WorldItemType.Goal:
            goalPosition[dragItemIndex].x += xloc - dragItemLastLoc.x
            goalPosition[dragItemIndex].y += yloc - dragItemLastLoc.y
        case WorldItemType.Pit:
            pitPosition[dragItemIndex].x += xloc - dragItemLastLoc.x
            pitPosition[dragItemIndex].y += yloc - dragItemLastLoc.y
        case WorldItemType.Obstacle:
            obstaclePosition[dragItemIndex].x += xloc - dragItemLastLoc.x
            obstaclePosition[dragItemIndex].y += yloc - dragItemLastLoc.y
        case WorldItemType.Robot:
            robotPosition.x += xloc - dragItemLastLoc.x
            robotPosition.y += yloc - dragItemLastLoc.y
        }
        
        dragItemLastLoc.x = xloc
        dragItemLastLoc.y = yloc
        setNeedsDisplayInRect(bounds)
    }
    
    override func mouseUp(theEvent: NSEvent) {
        //  Stop any drag
        dragItemType = WorldItemType.None
    }
    
    
    func getRobotIntersectType(point: CGPoint) -> WorldItemType
    {
        //  See if the click is on an obstacle
        var distance : CGFloat
        for index in 0..<obstacleEnabled.count {
            if (obstacleEnabled[index]) {
                distance = point.x - obstaclePosition[index].x
                distance *= distance
                distance += (point.y - obstaclePosition[index].y) * (point.y - obstaclePosition[index].y)
                distance = sqrt(distance)
                if (distance < obstacleRadius + robotRadius) {
                    return WorldItemType.Obstacle
                }
            }
        }
        
        //  See if the click is on a pit
        for index in 0..<pitEnabled.count {
            if (pitEnabled[index]) {
                distance = point.x - pitPosition[index].x
                distance *= distance
                distance += (point.y - pitPosition[index].y) * (point.y - pitPosition[index].y)
                distance = sqrt(distance)
                if (distance < pitRadius + robotRadius) {
                    return WorldItemType.Pit
                }
            }
        }
        
        //  See if the click is on a goal
        for index in 0..<goalEnabled.count {
            if (goalEnabled[index]) {
                distance = point.x - goalPosition[index].x
                distance *= distance
                distance += (point.y - goalPosition[index].y) * (point.y - goalPosition[index].y)
                distance = sqrt(distance)
                if (distance < goalRadius + robotRadius) {
                    return WorldItemType.Goal
                }
            }
        }
        
        return WorldItemType.None
    }
    
    //  Actions for two-state are 0->North, 1->West, 2->South, 3->East
    //  Actions for three-state are 0->Forward, 1->Backwards, 2->CCW turn, 3->CW turn
    func simulateAction(action: Int, forTime: CGFloat) ->Bool //  Return true simulation can continue
    {
        lastActionCausedStall = false
        
        //  Perform the action
        var newPoint = robotPosition
        if (robotType == .TwoState) {
            switch (action) {
            case 0:
                robotAngle = 0.0
            case 1:
                robotAngle = 90.0
            case 2:
                robotAngle = 180.0
            case 3:
                robotAngle = -90.0
            default:
                Swift.print("Invalid action sent to simulate method")
                return false
            }
            //  Add some angle variation
            robotAngle += CGFloat(DataSet.gaussianRandom(0.0, standardDeviation: 3.0))
            let radians = robotAngle * 3.1415926 / 180
            newPoint.x -= sin(radians) * robotSpeed * forTime
            newPoint.y += cos(radians) * robotSpeed * forTime
        }
        else {
            switch (action) {
            case 0:
                let radians = robotAngle * 3.1415926 / 180
                newPoint.x -= sin(radians) * robotSpeed * forTime
                newPoint.y += cos(radians) * robotSpeed * forTime
            case 1:
                let radians = robotAngle * 3.1415926 / 180
                newPoint.x += sin(radians) * robotSpeed * forTime
                newPoint.y -= cos(radians) * robotSpeed * forTime
            case 2:
                robotAngle += robotTurnSpeed * forTime
                if (robotAngle >= 180.0) { robotAngle -= 360.0 }
                return true     //  Turns can't get us in trouble
            case 3:
                robotAngle -= robotTurnSpeed * forTime
                if (robotAngle <= -180.0) { robotAngle += 360.0 }
                return true     //  Turns can't get us in trouble
            default:
                Swift.print("Invalid action sent to simulate method")
                return false
            }
        }
        
        //  Bounds check
        if (newPoint.x < 0 || newPoint.x > 100 || newPoint.y < 0 || newPoint.y > 100) {
            lastActionCausedStall = true
            return true     //  Don't commit the move, but continue
        }
        
        //  See if the new location is valid
        let intersect = getRobotIntersectType(newPoint)
        if (intersect == WorldItemType.Obstacle) {
            lastActionCausedStall = true
            return true     //  Don't commit the move, but continue
        }
        
        //  Commit the move
        robotPosition = newPoint
        
        //  See if we are at a stopping condition
        if (intersect == WorldItemType.Goal || intersect == WorldItemType.Pit) {
            return false
        }
        
        return true
    }
    
    //  Return the feature mapping of the state for a random state
    func getRandomStateForModel() -> [Double]
    {
        //  Get a position that is not on anything
        var posX : CGFloat = 0.0
        var posY : CGFloat = 0.0
        while (true) {
            posX = CGFloat(arc4random()) * 100.0 / CGFloat(UInt32.max)
            posY = CGFloat(arc4random()) * 100.0 / CGFloat(UInt32.max)
            let intersect = getRobotIntersectType(CGPoint(x: posX, y: posY))
            if (intersect == WorldItemType.None) { break }
        }
        
        if (robotType == .TwoState) {
            return [Double(posX), Double(posY)]
        }
        else {
            //  Get a random direction
            let direction = Double(arc4random()) * 360.0 / Double(UInt32.max)
            return [Double(posX), Double(posY), direction]
        }
    }
    
    //  Return result state from simulation for action from start state.  For this model, we will simulate for 0.25 seconds in 0.5 second increments
    func getResultStateForModel(startState: [Double], action: Int) -> [Double]
    {
        let oldPosition = robotPosition
        let oldAngle = robotAngle
        robotPosition = CGPoint(x: startState[0], y: startState[1])
        if (robotType == .ThreeState) {
            robotAngle = CGFloat(startState[2])
        }
        for _ in 0..<5 {
            simulateAction(action, forTime: 0.05)
        }
        
        var result : [Double]
        if (robotType == .TwoState) {
            result = [Double(robotPosition.x), Double(robotPosition.y)]
        }
        else {
            result = [Double(robotPosition.x), Double(robotPosition.y), Double(robotAngle)]
        }
        robotPosition = oldPosition
        robotAngle = oldAngle
        return result
    }
    
    //  Return the reward for performing an action
    func getRewardForModel(fromState: [Double], action: Int, toState: [Double]) -> Double
    {
        //  We only care about the end state for reward
        let endStateLocation = CGPoint(x: toState[0], y: toState[1])
        let intersect = getRobotIntersectType(endStateLocation)
        if (intersect == WorldItemType.Goal) { return 1.0 }
        if (intersect == WorldItemType.Pit) { return -1.0 }
        return -0.01
    }
    
    //  Routine to get the action policy (calculate V) for the current model
    func getActionPolicy()
    {
        //  Input has dimension 3 - x, y, and angle.  Output is 1 (V)
        do {
            try markov.fittedValueIteration(getRandomStateForModel, getResultingState: getResultStateForModel, getReward: getRewardForModel, fitModel: lrmodel)
        }
        catch {
            Swift.print("Error fitting V for policy")
        }
    }
    
    //  Routine to get the action for the current state
    func getCurrentAction() -> Int{
        let currentState = [Double(robotPosition.x), Double(robotPosition.y), Double(robotAngle)]
        return markov.getAction(currentState, getResultingState: getResultStateForModel, getReward: getRewardForModel, fitModel: lrmodel)
    }
    
    //  Routine to get the ordered action list for the current state
    func getCurrentActionOrder() -> [Int] {
        let currentState = [Double(robotPosition.x), Double(robotPosition.y), Double(robotAngle)]
        return markov.getActionOrder(currentState, getResultingState: getResultStateForModel, getReward: getRewardForModel, fitModel: lrmodel)
    }
    
    func showExpectedReward(granularity: Int, xscale : CGFloat, yscale : CGFloat) {
        //  Get the reward value at each grid location
        let posScale = 100.0 / Double(granularity)
        let posOffset = posScale * 0.5
        var reward = [Double](count: granularity * granularity, repeatedValue: 0.0)
        for x in 0..<granularity {
            let xpos = posOffset + (posScale * Double(x))
            for y in 0..<granularity {
                let ypos = posOffset + (posScale * Double(y))
                do {
                    reward[x*granularity+y] = try lrmodel.predictOne([xpos, ypos])[0]
                }
                catch {
                    return  //  Just leave on an error
                }
            }
        }
        
        //  Get the minimum and maximum values
        let minValue = reward.minElement()
        let maxValue = reward.maxElement()
        if let minValue = minValue, maxValue = maxValue {
            let rectSize = 100.0 / CGFloat(granularity)
            //  Draw each value
            for x in 0..<granularity {
                for y in 0..<granularity {
                    let rewardRect = NSMakeRect((CGFloat(x) * rectSize + robotRadius) * xscale,
                                                (CGFloat(y) * rectSize + robotRadius) * yscale,
                                                rectSize * xscale, rectSize * yscale)
                    var rectColor : NSColor
                    if (reward[x*granularity+y] >= 0) {
                        let scale  = CGFloat(reward[x*granularity+y] / maxValue)
                        rectColor = NSColor(red: 0.3, green: 0.3 + 0.7 * scale, blue: 0.3, alpha: 1.0)
                    }
                    else {
                        let scale  = CGFloat(reward[x*granularity+y] / minValue)
                        rectColor = NSColor(red: 0.3 + 0.7 * scale, green: 0.3, blue: 0.3, alpha: 1.0)
                    }
                    rectColor.setFill()
                    NSRectFill(rewardRect)
                }
            }
        }
    }
    
    func showActionsTwoState(atPosition: CGPoint, xscale : CGFloat, yscale : CGFloat) {
        let symbol = ["↑", "←", "↓", "→"]
        
        //  Set the label text attributes
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = 6.0
        paraStyle.alignment = NSTextAlignment.Center
        let attributes = [
            NSForegroundColorAttributeName: NSColor.blackColor(),
            NSParagraphStyleAttributeName: paraStyle,
            //NSTextAlignment: textalign,
            NSFontAttributeName: NSFont(name: "Helvetica Neue", size: 8)!
        ]
    
        let viewingState = [Double(atPosition.x), Double(atPosition.y)]
        let action = markov.getAction(viewingState, getResultingState: getResultStateForModel, getReward: getRewardForModel, fitModel: lrmodel)
        
        var point = atPosition
        point.x += robotRadius
        point.y += robotRadius
        point.x *= xscale
        point.y *= yscale
        symbol[action].drawAtPoint(point, withAttributes: attributes)
    }
   
    func showActionsThreeState(atPosition: CGPoint, xscale : CGFloat, yscale : CGFloat) {
        let symbol = [["↑", "↓", "⟲", "⟳"],         //  Facing up
                      ["↖︎", "↘︎", "⟲", "⟳"],       //  Facing up-left
                      ["←", "→", "⟲", "⟳"],         //  Facing left
                      ["↙︎", "↗︎", "⟲", "⟳"],       //  Facing down-left
                      ["↓", "↑", "⟲", "⟳"],         //  Facing down
                      ["↘︎", "↖︎", "⟲", "⟳"],       //  Facing down-right
                      ["→", "←", "⟲", "⟳"],         //  Facing right
                      ["↗︎", "↙︎", "⟲", "⟳"]]       //  Facing up-right
        let offsetDistance: CGFloat = 8.0
        let offset : [[CGFloat]] = [[0.0, 1.0],
                                    [-1.0, 1.0],
                                    [-1.0, 0.0],
                                    [-1.0, -1.0],
                                    [0.0, -1.0],
                                    [1.0, -1.0],
                                    [1.0, 0.0],
                                    [1.0, 1.0]]
        let angle : [Double] = [0.0, 45.0, 90.0, 135.0, 180.0, -135.0, -90.0, -45.0]
        
        //  Set the label text attributes
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = 6.0
        paraStyle.alignment = NSTextAlignment.Center
        let attributes = [
            NSForegroundColorAttributeName: NSColor.blackColor(),
            NSParagraphStyleAttributeName: paraStyle,
            //NSTextAlignment: textalign,
            NSFontAttributeName: NSFont(name: "Helvetica Neue", size: 8)!
        ]
        
        for index in 0..<8 {
            let viewingState = [Double(atPosition.x), Double(atPosition.y), angle[index]]
            let action = markov.getAction(viewingState, getResultingState: getResultStateForModel, getReward: getRewardForModel, fitModel: lrmodel)
            
            var point = atPosition
            point.x += robotRadius
            point.y += robotRadius
            point.x *= xscale
            point.y *= yscale
            point.x += offsetDistance * offset[index][0]
            point.y += offsetDistance * offset[index][1]
            symbol[index][action].drawAtPoint(point, withAttributes: attributes)
        }
    }
}
