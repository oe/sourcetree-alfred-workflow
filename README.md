# SourceTree alfred workflow
Search bookmarks in SourceTree and launch them in Alfred.

![usage demo](assets/usage-demo.gif)

*Credits*: This is a swift clone of [Alfred_SourceTree](https://github.com/yourtion/Alfred_SourceTree) by [yourtion](https://github.com/yourtion). Due to the latest release of macOS 12.3, python2 has been removed, which broke the original workflow. So I reimplemented this workflow in Swift. It should be much more stable and faster.

## Features
1. support fuzzy search
2. can open repo in your code editor directly by press <kbd>cmd</kbd> + <kbd>enter</kbd>, using VS Code by default, you can [custom it](#custom-your-perferred-code-editor)
3. can reveal repo in find by press <kbd>option</kbd> + <kbd>enter</kbd>


## Install
### Prepare
1. you must have [SourceTree](https://www.sourcetreeapp.com/) installed
2. you should have unlocked [Powerpack in Alfred](https://www.alfredapp.com/powerpack/)
3. make sure you have `swift` available in terminal.(**If you have `Xcode` installed, you can skip this step.**):
   1. type `swift --version` in terminal, if you don't see any version info output, following next step to install it.
   2. type `xcode-select --install` in terminal to install swift cli tools


### Install

[download workflow](https://github.com/oe/sourcetree-alfred-workflow/raw/main/SourceTree.alfredworkflow) then click the downloaded file to install

Promotion: using [sourcetree-custom-actions](https://github.com/oe/sourcetree-custom-actions) to add useful actions for SourceTree

## Usage

launch alfred then input `st` and `keyword` separated with a space to search bookmarks, press enter to launch the bookmark in SourceTree.

additionnal:
> select a bookmark,  press `cmd` + `enter` to open the repo in your favorite code editor, see [how to custom code editor](#custom-your-perferred-code-editor)
> select a bookmark,  press `option` + `enter` to reveal the repo in Finder


## Build script to binary
If you are using old Intel Chip Mac, you may experience the unbearable lagging, that's because of Swift JIT Compiler is pretty slow on Intel Chip.

You can follow the following steps to compile the workflow script to binary to speed up its response speed.

> enter `st $compile` in Alfred then press `enter` key

If you are using Apple Silicon Macs(like M1, M1 Pro), you can also compile the workflow for better performance


## Custom your perferred code editor
1. Open Alfred Preferences panel
2. find and click the `SourceTree` in **Wokflows** list
3. click the variable icon *[????]* in the top right to show the variable popup
4. add a variable named `EDITOR_CLI`, set its value to your favorite editor's cli name, such as:
	> `subl` for Sublime Text  
	> `xed` for Xcode  
   
   do not remove the variable `PATH`, if your editor cli name not
	found, you may edit `PATH` then append its path to existing
	value, be aware of the PATH format.  
   
5. click `save` button to save variable settings
6. click the bug ???? icon in the top right to show the debug log
7. try yourself, if it works, congratulations; if not, check the debug log, make sure the cli name is existing and correct, and `PATH` contains your cli

## Contributions and Support
I'm new to swift, feel free to make a pull request if you are willing to improve the code quality or its functions.
