# voxelized3d
experimental 3D voxel engine

***REQUIRES NVIDIA VIDEO CARD(will be optional)***

________________________________________________________________________
####INSTALLATION (LINUX + NVIDIA video card)

1)minimum OpenGL version 3.3 is required + libGL.so should be available in your PATH
2)install GLFW3
on ubuntu/debian it should be as simple as:
`sudo apt-get install libglfw3-dev`
or compile glfw3 from sources
3)CUDA is required (probably will be optional later), PATH also must be properly set
4)lapacke:
on ubuntu/debian:
`sudo apt-get install liblapacke-dev`
or compile from sources
5)install cmake(probably with GUI for simplicity)
on ubuntu/debian:
`sudo apt-get install cmake-gui`
6)compile cmake project in `bindings` directory of this project. After that copy outputted `libvoxelizedBindings.so` to the root of the project
7)install LDC https://dlang.org/download.html, DUB tool should be in your path after installation
8)run `dub run --build=release`

________________________________________________________________________

####INSTALLATION (Windows + NVIDIA video card)
Not yet tested
________________________________________________________________________


####Screenshots

![UMDC + sphere + noise (radius displacement)](imgs/umdc_sphere_displacement.png)

![sharp features are finally preserved !](imgs/sharp_features.png)

![difference](imgs/difference.png)

![some noise](imgs/noise1.png)

![noise terrain](imgs/noise_terrain.png)

![height map](imgs/heightmap1.png)

![another height map](imgs/heightmap2.png)

sampled on GPU(CUDA), extracted on CPU
![cuda1](imgs/cuda_gen1.png)