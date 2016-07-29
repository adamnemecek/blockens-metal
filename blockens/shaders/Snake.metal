//
//  Snake.metal
//  blockens
//
//  Created by Bjorn Tipling on 7/22/16.
//  Copyright (c) 2016 apphacker. All rights reserved.
//

#include "utils.h"

struct GridInfo {
    int gridDimension;
    float gridOffset;
    int numBoxes;
    int numVertices;
    int numColors;
};

enum GameTile {

    HeadUp, HeadDown, HeadLeft, HeadRight,
    TailUp, TailDown, TailLeft, TailRight,
    BodyHorizontal, BodyVertical,
    CornerUpLeft, CornerUpRight, CornerDownLeft, CornerDownRight,

    EmptyTile, GrowTile,

};

vertex VertexOut gameTileVertex(uint vid [[ vertex_id ]],
                                     constant packed_float2* position  [[ buffer(0) ]],
                                     constant packed_float4* color    [[ buffer(1) ]],
                                     constant GridInfo* gridInfo [[ buffer(2) ]],
                                     constant int* gameTiles [[ buffer(3) ]],
                                     constant int* boxTiles [[ buffer(4) ]]) {

    VertexOut outVertex;

    int dimension = gridInfo->gridDimension;
    int numVertices = gridInfo->numVertices;

    int tileNum = vid / numVertices;
    int positionIndex = vid % numVertices;

    int gameTile = gameTiles[tileNum];
    int boxNum = boxTiles[tileNum];

    int col = boxNum % dimension;
    int row = boxNum / dimension;

    float2 pos = position[positionIndex];
    float2 orgPosition = float2(pos[0], pos[1]);

    // Scale box size based on dimension where dimension is the width and height as both are the same value.
    pos /= dimension;

    // Translate box to bottom right (-1, -1) position.
    pos[0] -= fabs(orgPosition[0]) - fabs(pos[0]);
    pos[1] -= fabs(orgPosition[1]) - fabs(pos[1]);

    // Translate box to its colum and row position from bottom right.
    pos[0] += gridInfo->gridOffset * float(col);
    pos[1] += gridInfo->gridOffset * float(row);

    outVertex.position = float4(pos[0], pos[1], 0.0, 1.0);

    if (gameTile < EmptyTile) {
        outVertex.color = color[0];
    } else {
        outVertex.color = color[2];
    }
    
    return outVertex;
};

fragment half4 gameTileFragment(VertexOut inFrag [[stage_in]]) {
    return half4(inFrag.color);
};