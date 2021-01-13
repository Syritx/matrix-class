import Foundation
import MetalKit
import ModelIO
import simd

//MARK: SHADER CLASS
struct Uniforms {
    var modelViewMatrix: float4x4
    var projectionMatrix: float4x4
}


//MARK: RENDERER CLASS
class Rendering: NSObject, MTKViewDelegate {
    
    
    var matrix: Matrix4!
    
    var rotation: Float = 0
    public var position: float3 = float3(0,0,-45)
    public let speed: Float = 2
    
    let device: MTLDevice
    let mtkView: MTKView
    let commandQueue: MTLCommandQueue
        
    var vertexDescriptor: MTLVertexDescriptor!
    var renderPipeline: MTLRenderPipelineState!
    
    var meshes: [MTKMesh] = []
    
    init(view: MTKView, device: MTLDevice) {
        self.mtkView = view
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        
        matrix = Matrix4()
        
        super.init()
        loadModel()
        buildPipeline()
    }
    
    //MARK: MODEL LOADER
    func loadModel() {
        let modelURL = Bundle.main.url(forResource: "container", withExtension: "obj")
        
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        
        self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        
        do {
            (_, meshes) = try MTKMesh.newMeshes(asset: asset, device: device)
        }
        catch {
            fatalError("Could not extract meshes from Model I/O asset")
        }
    }
    
    //MARK: PIPELINE
    func buildPipeline() {
        guard let library = device.makeDefaultLibrary() else { fatalError("cannot make library") }
        
        let vertexFunc = library.makeFunction(name: "vertex_main")
        let fragmentFunc = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            renderPipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state object: \(error)")
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    //MARK: RENDERING
    func draw(in view: MTKView) {
        
        rotation += 0.5/Float(mtkView.preferredFramesPerSecond)
        let angle = -rotation
        
        let modelMatrix = matrix.rotateBy(axis: float3(0,1,0), radians: angle) * matrix.scale(s: 2)
        let viewMatrix = matrix.translate(position: float3(0,0, -45))
        let modelViewMatrix = viewMatrix * modelMatrix
                
        let projectionMatrix = matrix.perspective(radians: Float.pi/3, aspect: 1, nearZ: 0.1, farZ: 1000)
        
        var uniforms = Uniforms(modelViewMatrix: modelViewMatrix, projectionMatrix: projectionMatrix)
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        if let renderPassDescriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable {
            let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            
            for mesh in meshes {
                let vertexBuffer = mesh.vertexBuffers.first!
                commandEncoder?.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
                commandEncoder?.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
                commandEncoder?.setRenderPipelineState(renderPipeline)
                
                for submesh in mesh.submeshes {
                    let indexBuffer = submesh.indexBuffer
                    commandEncoder?.drawIndexedPrimitives(type: submesh.primitiveType,
                                                         indexCount: submesh.indexCount,
                                                         indexType: submesh.indexType,
                                                         indexBuffer: indexBuffer.buffer,
                                                         indexBufferOffset: indexBuffer.offset)
                }
            }
            commandEncoder?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}
