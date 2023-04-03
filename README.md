# Falcon Slicer

## FEATURES

Key features that make this slicer:
- Live previewing of slicer setting (real-time slicing) - based on GPU slicing
- Live tracking of model geometry changes - quick reimport of model without losing slicing / print settings
- Versioning of project and global slicing setting so that you can itterate fastly
- Modern .3fm file format for input and output to 3D printer
- Fuzzy search for slicing features and text based editing support in style of VSCode Settings
- Shortcut first editor in style of blender or other CAD tools
- CTRL + T launches cammand pallete
- Zen minimal UI that doesn't get into your way
    - Options for docking
    - dark/light mode
    - Object settings like in game engine editor
- Default modern slicing features:
    - Adaptive layer height
    - Arachne slicing engine
    - Dynamic infill density
    - Lightning infill
    - Tree support
    - Auto support painter
- Download and import models from OnShape with one click

## Technology stack
This slicer is build on top of:
- [Zig](https://ziglang.org/) programing language 
    - modern, portable, fast, simple language -> succesor to C
    - compiles C and C++ code with libc support
    - build system that enables only dependency for user to be Zig + Git
- [Mach core](https://machengine.org/gpu/) provides truly-cross-platform window + input + WebGPU API
    - provides graphics API on desktop, web and mobile (in the future)
    - writing compute shaders for slicing on all platforms
- [WebGPU](https://www.w3.org/TR/webgpu/) is a new web API that exposes modern computer graphics capabilities, specifically Direct3D 12, Metal, and Vulkan, for performing rendering and computation operations on a GPU.
    - thing wrapper over popular APIs [source article](https://developer.chrome.com/en/docs/web-platform/webgpu/#:~:text=webgpu%20is%20a%20new%20web,graphics%20processing%20unit%20(GPU).&text=This%20goal%20is%20similar%20to,more%20advanced%20features%20of%20GPUs.)
    - enables compute capabilities and no need to write code multiple times for different platform with [WSGL](https://gpuweb.github.io/gpuweb/wgsl/)
- [Nuklear](https://github.com/Immediate-Mode-UI/Nuklear) a single-header ANSI C immediate mode cross-platform GUI library
    - main thing to use this over [ImGui](https://github.com/ocornut/imgui) is: portability, efficiency and simplicity
- [lib3mf](https://github.com/3MFConsortium/lib3mf) is a C++ implementation of the 3D Manufacturing Format file standard.
    - for procesing .3mf with model data files and outputing out .3fm files with G-code
- [libslic3r](https://slic3r.org/) a C++ library for building custom applications on top of the Slic3r internal algorithms.

## License and attribution
This work is licensed under a the GNU Affero General Public License, version 3
