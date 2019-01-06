# Real Time Path Tracer for iOS

![alt tag](https://www.dropbox.com/s/m5ufa0b7u7aytcf/SCENE_3.JPG?raw=1)

This is a [Path Tracer](https://en.wikipedia.org/wiki/Path_tracing) for iOS. 

Originally coded in 2014, this app renders scenes in real time using monte carlo path tracing. 

For every single pixel on the screen, it casts a ray through that pixel, lets the ray bounce around the scene collecting information about lighting, global illumination, and object positioning, and then uses that information to construct an image of the scene. 

Because this all runs in a Metal shader, it can do this at about 30 fps. As it runs in real time the user can also construct the scene in real time, including changing camera position, colors, sphere positions and properties. All while seeing the path tracer render the scene.

### TODO
- Update to Metal 2
- Switch to a MKTView for rendering instead of a UIImageView. 
- Finalize support for more objects than just Spheres

### Download
[You can build form source, or download from the app store here](https://itunes.apple.com/us/app/real-time-path-tracer/id1090761030?mt=8)
