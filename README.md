# SourceTree alfred workflow
Search bookmarks in SourceTree and launch them in Alfred.

Notice: This is a swift clone of [Alfred_SourceTree](https://github.com/yourtion/Alfred_SourceTree) by [yourtion](https://github.com/yourtion). Due to latest release of macOS 12.3, python2 has been removed which broken this workflow. So I reimplemented this workflow in Swift, It should be much more stable and faster.

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

