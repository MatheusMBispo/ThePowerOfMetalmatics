import Cocoa
import MetalKit
import PlaygroundSupport
/*:
 # Instructions
 
 * All scenes react to music.
 * Click the arrows to switch scenes.
 * You can interact with the camera by clicking and dragging or by using the mouse scroll.
 
 */

let device = MTLCreateSystemDefaultDevice()
let rect = CGRect(x: 0, y: 0, width: 500, height: 500)
let view = GameView(frame: rect, device: device)
PlaygroundPage.current.liveView = view

/*:
 #### You can switch the scene here too
 * Scene 1 - The red dancing line
 * Scene 2 - Infinity spheres
 * Scene 3 - Wave Ball
 * Scene 4 - Tribute to Siri
 */
view.present(scene: .Scene4)

/*:
 # The Power of Metalmatics
 
 ## Introduction
 
 From the beginning, mathematics serves as the primary basis for computing, helping man break boundaries that were once insurmountable. Over time, computing has not only helped solve major problems but also began to charm people!
 
 And it was through this existent artistic vein in computing added to the beauty that we already found in mathematical functions that was borned the computer graphics!
 
 ## Metal  ![Metal Image](Metal.png)
 
 This project will show you, at runtime, the magic of mathematics added to the power of metal, producing a beautiful and mysterious visual.
 
 So that it was possible to accomplish this task nothing better than metal. Performing calculations on the GPU side makes all 3D renderings extremely fast.
 
 In addition to offering us endless possibilities!
 
 ## Metalmatics
 
 The relationship between mathematics and Metal can produce really beautiful results!
 Choose a scene and see yourself!
 
 ### Scene 1 - The red dancing line:
 
 Using the raymarching technique to create 3D objects and manipulating them using the functions of **sine** and **cosine**.
 
 ![Scene 1](Scene1.png)
 
### Scene 2 - Infinity spheres:
 
 Using the raymarching technique to create the 3D spheres and fractioning the rays of the technique to obtain the infinity effect.
 
 ![Scene 2](Scene2.png)
 
### Scene 3 - Wave Ball:
 
 Using the raymarching technique to create the 3D sphere and using sine and cosine to perform the distortions on the screen.
 
 ![Scene 3](Scene3.png)
 
### Scene 4 - Tribute to Siri:
 
 Tribute to Siri, using sine and cosine to generate the waves.
 
 ![Scene 4](Scene4.png)
 
 */
