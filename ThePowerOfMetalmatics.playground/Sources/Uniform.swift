import MetalKit

//MARK: - STRUCTS
//---------------------
// STRUCTS
//---------------------

public struct Uniform {
    public var time: Float
    public var mouse: float3
    public var axis: float3
    public var magnitude: Float
    
    public init(time: Float, mouse: float3, axis: float3){
        self.time = time
        self.mouse = mouse
        self.axis = axis
        self.magnitude = 0
    }
};
