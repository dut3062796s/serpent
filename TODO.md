TODO: SciFi Demo

 - [x] Quick Hack 1: Fix delta time for velocity based movement of robots
 - [x] Fix (finally) the Batch renderer to handle massive amounts of sprites
 - [ ] Clip offscreen entities (don't draw them at all, *and* scissor the view
 - [ ] Abstract Shader into ShaderCache with handles
 - [ ] Abstract Texture into TextureCache with handles
 - [ ] Verify NoopPipeline no longer crashes!
 - [ ] Add Animation module (Animation, Timeline, Processor)
    - Likely that Animation is a class, Timeline is a struct, allowing
      more specific implementations in future (property based, etc.)
 - [ ] Bind a player Entity to keyboard so we can move it
 - [ ] Design some basic basic level to run through
 - [ ] Add some collisiony type things.
 - [ ] Figure out how to have more than one scene. :)
 - [ ] Add mainFBO to Pipeline

Make Life Easier:

Try to get `autoformat`, `dfmt` and `misspell` packaged up for
Solus to simplify `update_format.sh` usage.
