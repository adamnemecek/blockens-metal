//
// Created by Bjorn Tipling on 8/6/16.
// Copyright (c) 2016 apphacker. All rights reserved.
//

import Foundation
import MetalKit

struct StringInfo {
    var gridWidth: Int32
    var gridHeight: Int32

    // Character vertices are multiplied by these scales from normal coordinates
    var xScale: Float32
    var yScale: Float32

    // Character vertices are added by these values after scale has been applied.
    var xPadding: Float32
    var yPadding: Float32


    var numBoxes: Int32
    var numVertices: Int32
    var numCharacters: Int32
    var numSegments: Int32
}

class StringRenderer: Renderer  {

    let renderUtils: RenderUtils

    var pipelineState: MTLRenderPipelineState! = nil
    var stringVertexBuffer: MTLBuffer! = nil
    var boxTilesBuffer: MTLBuffer! = nil
    var segmentTrackerBuffer: MTLBuffer! = nil
    var stringInfo: StringInfo! = nil

    // Sixes vertices for two triangles to make a rectangle.
    let numVerticesInARectangle: Int32 = 6
    let gridWidth: Int32 = 5
    let gridHeight: Int32 = 8

    init(utils: RenderUtils, xScale: Float32, yScale: Float32, xPadding: Float32, yPadding: Float32) {
        renderUtils = utils
        stringInfo = StringInfo(
                gridWidth: gridWidth,
                gridHeight: gridHeight,
                xScale: xScale,
                yScale: yScale,
                xPadding: xPadding,
                yPadding: yPadding,
                numBoxes: gridWidth * gridHeight,
                numVertices: 0,
                numCharacters: 0,
                numSegments: 0)
    }

    func calcNumVertices() {
        stringInfo.numVertices = stringInfo.numSegments
        stringInfo.numVertices *= numVerticesInARectangle

    }


    func update(boxTiles: [Int32], segmentTracker: [Int32]) {
        stringInfo.numCharacters = Int32(segmentTracker.count)
        stringInfo.numSegments = 0
        for segmentCount in segmentTracker {
            stringInfo.numSegments += segmentCount
        }
        calcNumVertices()

        let bData = boxTilesBuffer.contents()
        let bvData = UnsafeMutablePointer<Int32>(bData + 0)
        bvData.initializeFrom(boxTiles)

        let tData = segmentTrackerBuffer.contents()
        let tvData = UnsafeMutablePointer<Int32>(tData + 0)
        tvData.initializeFrom(segmentTracker)
    }

    func loadAssets(device: MTLDevice, view: MTKView, frameInfo: FrameInfo) {

        pipelineState = renderUtils.createPipeLineState("stringVertex", fragment: "stringFragment", device: device, view: view)

        stringVertexBuffer = renderUtils.createRectangleVertexBuffer(device, bufferLabel: "string vertices")
        boxTilesBuffer = renderUtils.createSizedBuffer(device, bufferLabel: "string box tile vertices")
        segmentTrackerBuffer = renderUtils.createSizedBuffer(device, bufferLabel: "segment tracker vertices")

        print("loading string assets done")
    }

    func render(renderEncoder: MTLRenderCommandEncoder) {

        renderUtils.setPipeLineState(renderEncoder, pipelineState: pipelineState, name: "string")

        renderEncoder.setVertexBuffer(stringVertexBuffer, offset:0 , atIndex: 0)

        renderUtils.drawPrimitives(renderEncoder, vertexCount: renderUtils.rectangleVertexData.count)
    }


}