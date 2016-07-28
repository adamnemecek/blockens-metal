//
//  GameViewController.swift
//  blockens
//
//  Created by Bjorn Tipling on 7/22/16.
//  Copyright (c) 2016 apphacker. All rights reserved.
//

import Cocoa
import MetalKit

let ConstantBufferSize = 1024*1024

let vertexData:[Float] = [
    -1.0, -1.0,
    -1.0,  1.0,
    1.0, -1.0,

    1.0, -1.0,
    -1.0,  1.0,
    1.0,  1.0,
]

let vertexColorData:[Float] = [
    0.0, 0.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    0.0, 1.0, 0.0, 1.0,
]

class GameViewController: NSViewController, MTKViewDelegate {
    
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    
    let inflightSemaphore = dispatch_semaphore_create(1)
    var currentTickWait = MAX_TICK_MILLISECONDS

    var timer: NSTimer?
    var gameStatus: GameStatus = GameStatus.Running

    let snake: SnakeController = SnakeController(data: gridInfoData)

    override func viewDidLoad() {
        
        super.viewDidLoad()
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let gameWindow = appDelegate.getWindow()
        gameWindow.addKeyEventCallback(handleKeyEvent)
        
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { // Fallback to a blank NSView, an application could also fallback to OpenGL here.
            print("Metal is not supported on this device")
            self.view = NSView(frame: self.view.frame)
            return
        }

        // Setup view properties.
        let view = self.view as! MTKView
        view.delegate = self
        view.device = device
        view.sampleCount = 4
        loadAssets()
        resetGame()
    }

    func loadAssets() {

        let view = self.view as! MTKView
        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
        snake.renderer().loadAssets(device, view: view, gridInfoData: gridInfoData)
    }

    func resetGame() {
        currentTickWait = MAX_TICK_MILLISECONDS
        snake.reset()
        scheduleTick()
    }

    func handleKeyEvent(event: NSEvent) {
        if Array(movementMap.keys).contains(event.keyCode) {
            let newDirection = movementMap[event.keyCode]!
            switch (newDirection) {
                case Direction.Down:
                    if snake.oneEighty(Direction.Up) {
                        return
                    }
                    break
                case Direction.Up:
                    if snake.oneEighty(Direction.Down) {
                        return
                    }
                    break
                case Direction.Left:
                    if snake.oneEighty(Direction.Right) {
                        return
                    }
                    break
                case Direction.Right:
                    if snake.oneEighty(Direction.Left) {
                        return
                    }
                    break
            }
            snake.setDirection(newDirection)
            tick()
            return
        }

        switch event.keyCode {
            case S_KEY:
                switch gameStatus {
                    case GameStatus.Running:
                        break
                    case GameStatus.Stopped:
                        resetGame()
                        break
                    default:
                        gameStatus = GameStatus.Running
                        scheduleTick()
                        break
                }
                break
            case P_KEY:
                gameStatus = GameStatus.Paused
                break
            default:
                // Unhandled key code.
                break
        }

    }

    func scheduleTick() {
        if gameStatus != GameStatus.Running {
            return
        }
        if timer?.valid ?? false {
            // If timer isn't nil and is valid don't start a new one.
            return
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(Double(currentTickWait) / 1000.0, target: self,
                selector: #selector(GameViewController.tick), userInfo: nil, repeats: false)
    }


    func tick() {
        if let currentTimer = timer {
            currentTimer.invalidate()
        }
        if gameStatus != GameStatus.Running {
            return
        }
        if (snake.eatFoodIfOnFood()) {
            currentTickWait -= log_e(currentTickWait)
        }
        if !snake.move() {
            print("Collision")
            gameStatus = GameStatus.Stopped
            return
        }
        scheduleTick()
    }
    
    func drawInMTKView(view: MTKView) {
        // Use semaphore to encode 3 frames ahead.
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER)

        snake.update()
        let commandBuffer = commandQueue.commandBuffer()
        commandBuffer.label = "Frame command buffer"

        // Use completion handler to signal the semaphore when this frame is completed allowing the encoding of the next frame to proceed.
        // Use capture list to avoid any retain cycles if the command buffer gets retained anywhere besides this stack frame.
        commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
            if let strongSelf = self {
                dispatch_semaphore_signal(strongSelf.inflightSemaphore)
            }
            return
        }

        if let renderPassDescriptor = view.currentRenderPassDescriptor, currentDrawable = view.currentDrawable {
            let parallelCommandEncoder = commandBuffer.parallelRenderCommandEncoderWithDescriptor(renderPassDescriptor)

            // Render snake
            let snakeRenderEncoder = parallelCommandEncoder.renderCommandEncoder()
            snake.renderer().render(snakeRenderEncoder)


            parallelCommandEncoder.endEncoding()
            commandBuffer.presentDrawable(currentDrawable)
        }
        commandBuffer.commit()
    }

    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        // Pass through and do nothing.
    }
}
