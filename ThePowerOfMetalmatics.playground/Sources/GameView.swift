import MetalKit
import AVFoundation

//MARK: - GAME VIEW
//---------------------
// GAME VIEW
//---------------------

// Enum with the scenes
public enum SceneEnum: Int {
    case Scene1
    case Scene2
    case Scene3
    case Scene4
}

// View responsible for building the base of the Metal environment.
public class GameView: MTKView {
    
    var commandQueue: MTLCommandQueue!
    private var presentScene: Scene?
    private var scenes = [Scene]()
    private var currentScene = 0
    
    var drumAudioPlayer: AVAudioPlayer!
    var mainAudioPlayer: AVAudioPlayer!
    
    override public init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        
        configureView()
        
        guard let url_drum = Bundle.main.url(forResource: "Audio_Drum", withExtension: "mp3") else {
            fatalError("Error on load resource")
        }
        
        drumAudioPlayer = try? AVAudioPlayer(contentsOf: url_drum)
        drumAudioPlayer?.isMeteringEnabled = true
        drumAudioPlayer?.play()
        drumAudioPlayer?.numberOfLoops = -1
        
        guard let url_main = Bundle.main.url(forResource: "Audio_Music", withExtension: "mp3") else {
            fatalError("Error on load resource")
        }
        
        mainAudioPlayer = try? AVAudioPlayer(contentsOf: url_main)
        mainAudioPlayer?.isMeteringEnabled = true
        mainAudioPlayer?.play()
        mainAudioPlayer?.numberOfLoops = -1
        
        scenes.append(Scene_1(audioPlayer: drumAudioPlayer))
        scenes.append(Scene_2(audioPlayer: drumAudioPlayer))
        scenes.append(Scene_3(audioPlayer: drumAudioPlayer))
        scenes.append(Scene_4(audioPlayer: drumAudioPlayer))

        self.setPresentScene(scene: scenes[currentScene])
        
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        configureView()
    }
    
    //Make initial view settings
    public func configureView() {
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = self.device!.makeCommandQueue()!
        self.framebufferOnly = false
        
        configureButtons()
    }
    
    //Create the view buttons
    func configureButtons() {
        let buttonLeft_Unpressed = NSImage(named: NSImage.Name(rawValue: "Image_Left_Unpressed"))!
        
        let buttonLeft_Pressed = NSImage(named: NSImage.Name(rawValue: "Image_Left_Pressed"))!
        
        let buttonLeft = NSButton(image: buttonLeft_Unpressed,
                                  target: self, action:  #selector(nextLeftScene))
        buttonLeft.isTransparent = true
        buttonLeft.frame = NSRect(origin: CGPoint(x: 0, y: 0),
                                  size: NSSize(width: 60, height: 60))
        buttonLeft.alternateImage = buttonLeft_Pressed
        
        self.addSubview(buttonLeft)
        
        let buttonRight_Unpressed = NSImage(named: NSImage.Name(rawValue: "Image_Right_Unpressed"))!
        
        let buttonRight_Pressed = NSImage(named: NSImage.Name(rawValue: "Image_Right_Pressed"))!
        
        let buttonRight = NSButton(image: buttonRight_Unpressed,
                                   target: self, action: #selector(nextRightScene))
        
        buttonRight.isTransparent = true
        buttonRight.frame = NSRect(origin: CGPoint(x: self.bounds.width - 60,
                                                   y: 0),
                                   size: NSSize(width: 60, height: 60))
        buttonRight.alternateImage = buttonRight_Pressed
        
        self.addSubview(buttonRight)

    }
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        presentScene?.render(commandQueue: commandQueue)
    }
    
    private func setPresentScene(scene: Scene) {
        scene.setupSceneWith(view: self, device: device!)
        self.presentScene = scene
    }
    
    //Send the mouse data for the uniform in present scene
    public override func mouseDragged(with event: NSEvent) {
        self.presentScene?.uniform.mouse += normalize(float3(
            Float(event.deltaX/100),
            Float(event.deltaY/100), 1.0))
    }
    
    //Send the mouse data for the uniform in present scene
    public override func scrollWheel(with event: NSEvent) {
        if let scene = presentScene {
            
            if scene.uniform.axis.z < 0 &&  event.scrollingDeltaY < 0{
                return
            }
            
            if scene.uniform.axis.z > 9 &&  event.scrollingDeltaY > 0{
                return
            }
            
            self.presentScene?.uniform.axis += float3(0, 0, Float(event.scrollingDeltaY));
        }
    }
    
    @objc
    public func nextRightScene() {
        if currentScene >= scenes.count - 1 {
            currentScene = 0
        }else {
            currentScene += 1
        }
        
        self.setPresentScene(scene: scenes[currentScene])
    }
    
    @objc
    public func nextLeftScene() {
        if currentScene <= 0 {
            currentScene = scenes.count - 1
        }else {
            currentScene -= 1
        }
        self.setPresentScene(scene: scenes[currentScene])
    }
    
    public func present(scene: SceneEnum) {
        currentScene = scene.rawValue
        self.setPresentScene(scene: scenes[scene.rawValue])
    }
}
