//
//  Background.metal
//  blockens
//
//  Created by Bjorn Tipling on 7/28/16.
//  Copyright (c) 2016 apphacker. All rights reserved.
//

#include "utils.h"

struct BGInfo {
    float viewDiffRatio;
};

vertex VertexTextureOut backgroundVertex(uint vid [[ vertex_id ]],
                                     constant BGInfo* bgInfo [[ buffer(0) ]],
                                     constant packed_float2* position  [[ buffer(1) ]]) {

    VertexTextureOut outVertex;

    float2 pos = position[vid % 6];

    if (vid < 6) {
        pos[1] = pushUpYByRatio(pos[1], bgInfo->viewDiffRatio);
    } else {
        pos[1] = pushDownYByRatio(pos[1], bgInfo->viewDiffRatio);
    }
    outVertex.vid = vid;
    outVertex.position = float4(pos[0], pos[1], 1.0, 1.0);

    return outVertex;
}

fragment float4 backgroundFragment(VertexTextureOut inFrag [[stage_in]]) {

    if (inFrag.vid < 6) {
        float4 blue = rgbaToNormalizedGPUColors(2, 166, 214);
        return blue;
    }

    return float4(1.0, 1.0, 1.0, 1.0);

}