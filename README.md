# SourceTree alfred workflow
Search bookmarks in SourceTree and launch them in Alfred.

![usage demo](assets/usage-demo.gif)

*Credits*: This is a swift clone of [Alfred_SourceTree](https://github.com/yourtion/Alfred_SourceTree) by [yourtion](https://github.com/yourtion). Due to the latest release of macOS 12.3, python2 has been removed, which broke the original workflow. So I reimplemented this workflow in Swift. It should be much more stable and faster.

## Install
### Prepare
1. you must have [SourceTree](https://www.sourcetreeapp.com/) installed
2. you should have unlocked [Powerpack in Alfred](https://www.alfredapp.com/powerpack/)
3. make sure you have `swift` available in terminal.(**If you have `Xcode` installed, you can skip this step.**):
   1. type `swift --version` in terminal, if you don't see any version info output, following next step to install it.
   2. type `xcode-select --install` in terminal to install swift cli tools


### Install

[download workflow](https://github.com/oe/sourcetree-alfred-workflow/raw/main/SourceTree.alfredworkflow) then click the downloaded file to install

## Usage
launch alfred then input `st` and `keyword` separated with a space to search bookmarks, press enter to launch the bookmark in SourceTree.

> press `cmd` + `enter` to reveal the repo in Finder

## Optimize for Intel Chip Mac
If you are using old Intel Chip Mac, you may experience the unbearable lagging, that's because of Swift JIT Compiler is pretty slow on Intel Chip.

You can follow the following steps to compile the workflow script to binary to speed up its response speed.

> enter `st $compile` in Alfred then press `enter` key

*If you are using Apple Silicon Macs(like M1, M1 Pro), you can also compile the workflow, but only a little bit faster*


## Contributions and Support
I'm new to swift, feel free to make a pull request if you are willing to improve the code quality or its functions.
