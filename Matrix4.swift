//
//  Matrix4.swift
//  west-gorovask
//
//  Created by Syritx on 2021-01-07.
//

import Foundation
import simd



extension float4x4 {
    init(scaleBy s: Float) {
        self.init(float4(s, 0, 0, 0),
                  float4(0, s, 0, 0),
                  float4(0, 0, s, 0),
                  float4(0, 0, 0, 1))
    }
 
    init(rotationAbout axis: float3, by angleRadians: Float) {
        let x = axis.x, y = axis.y, z = axis.z
        let c = cosf(angleRadians)
        let s = sinf(angleRadians)
        let t = 1 - c
        self.init(float4( t * x * x + c,     t * x * y + z * s, t * x * z - y * s, 0),
                  float4( t * x * y - z * s, t * y * y + c,     t * y * z + x * s, 0),
                  float4( t * x * z + y * s, t * y * z - x * s,     t * z * z + c, 0),
                  float4(                 0,                 0,                 0, 1))
    }
 
    init(translationBy t: float3) {
        self.init(float4(   1,    0,    0, 0),
                  float4(   0,    1,    0, 0),
                  float4(   0,    0,    1, 0),
                  float4(t[0], t[1], t[2], 1))
    }
    
    init(orthographicProjection left: Float, right: Float, bottom: Float, top: Float, zNear: Float, zFar: Float) {
        let invRL = 1.0 / (right - left)
        let invTB = 1.0 / (top - bottom)
        let invFN = 1.0 / (zFar - zNear)
        
        self.init(float4(2*invRL, 0, 0, 0),
                  float4(0, 2*invTB, 0, 0),
                  float4(0, 0, -2 * invFN, 0),
                  float4(-(right+left) * invRL, -(top+bottom) * invTB, -(zFar + zNear) * invFN, 1))
    }
    
 
    init(perspectiveProjectionFov fovRadians: Float, aspectRatio aspect: Float, nearZ: Float, farZ: Float) {
        let yScale = 1 / tan(fovRadians * 0.5)
        let xScale = yScale / aspect
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2 * farZ * nearZ / zRange
 
        let xx = xScale
        let yy = yScale
        let zz = zScale
        let zw = Float(-1)
        let wz = wzScale
 
        self.init(float4(xx,  0,  0,  0),
                  float4( 0, yy,  0,  0),
                  float4( 0,  0, zz, zw),
                  float4( 0,  0, wz,  0))
    }
}

class Matrix4 {
    
    
    func translate(position: float3) -> float4x4 {
        
        let result = float4x4(translationBy: position)
        return result
    }
    
    func perspective(radians: Float, aspect: Float, nearZ: Float, farZ: Float) -> float4x4 {
        
        return float4x4(perspectiveProjectionFov: radians, aspectRatio: aspect, nearZ: nearZ, farZ: farZ)
    }
    
    func orthographic(width: Float, height: Float, zNear: Float, zFar: Float) -> float4x4 {
        
        let left: Float = -width/2
        let right: Float = width/2
        
        let bottom: Float = -height/2
        let top: Float = height/2
        
        return float4x4(orthographicProjection: left, right: right, bottom: bottom, top: top, zNear: zNear, zFar: zFar)
    }
    
    
    func rotateBy(axis: float3, radians: Float) -> float4x4 {
        return float4x4(rotationAbout: axis, by: radians)
    }
    
    func scale(s: Float) -> float4x4 {
        return float4x4(scaleBy: s)
    }
}
