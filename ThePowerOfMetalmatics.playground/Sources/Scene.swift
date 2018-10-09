import MetalKit

//MARK: - SCENE
//---------------------
// SCENE
//---------------------

public protocol Scene {
    var view: GameView! {get set}
    var device: MTLDevice! {get set}
    var computePipelineState: MTLComputePipelineState! {get set}
    var uniform : Uniform {get set}
    
    func setupSceneWith(view: GameView, device: MTLDevice)
    func render(commandQueue: MTLCommandQueue)
}
