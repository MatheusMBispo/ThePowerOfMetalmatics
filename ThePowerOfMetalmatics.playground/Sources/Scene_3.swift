import MetalKit
import AVFoundation

public class Scene_3: Scene {
    
    public var view: GameView!
    public var device: MTLDevice!
    public var computePipelineState: MTLComputePipelineState!
    
    public var uniform = Uniform(time: 0, mouse: float3(), axis: float3())
    var uniformBuffer: MTLBuffer?
    
    var audioPlayer: AVAudioPlayer
    
    public init(audioPlayer: AVAudioPlayer){
        self.audioPlayer = audioPlayer
    }
    
    public func setupSceneWith(view: GameView, device: MTLDevice) {
        self.view   = view
        self.device = device
        
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniform>.size, options: [])
        
        do {
            computePipelineState = try self.buildComputePipelineWithDevice()
        } catch {
            print("Unable to compile render pipeline state.  Error info: \(error)")
            return
        }
    }
    
    public func render(commandQueue: MTLCommandQueue) {
        if let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder(){
            commandEncoder.setComputePipelineState(computePipelineState)
            let texture = drawable.texture
            
            commandEncoder.setTexture(texture, index: 0)
            commandEncoder.setBuffer(uniformBuffer, offset: 0, index: 0)
            
            update()
            
            let threadGroupCount = MTLSizeMake(8, 8, 1)
            let threadGroups = MTLSizeMake(texture.width / threadGroupCount.width, texture.height / threadGroupCount.height, 1)
            commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
    
    
    public func buildComputePipelineWithDevice() throws -> MTLComputePipelineState {
        
        var path = Bundle.main.path(forResource: "Shader_3", ofType: "metal")
        let source = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        
        path = Bundle.main.path(forResource: "Utils", ofType: "metal")
        let utils = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        
        let library = try device?.makeLibrary(source: source + utils, options: nil)
        let computeFunction = library!.makeFunction(name: "compute")
        
        return try device!.makeComputePipelineState(function: computeFunction!)
    }
    
    public func update() {
        uniform.time += 0.016
        audioPlayer.updateMeters()
        uniform.magnitude = audioPlayer.averagePower(forChannel: 0).rounded()
        let pointer = uniformBuffer?.contents()
        memcpy(pointer, &uniform, MemoryLayout<Uniform>.size)
    }
}
