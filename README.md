# AccessControlKitty
Xcode extension to change the access control level of Swift code selection

### Features
- Change or remove access control level of the currently selected Swift code
- Supports `public`, `private`, `fileprivate`, `internal` and removing any annotation. 

![Demo of changing access level](https://media.giphy.com/media/7zxZhrrxurVXg1oh5m/giphy.gif)

### Unfeatures
- It’s not particularly smart, so for example it doesn’t know if a function can’t be made public because it relies on an internal type.  And it certainly doesn’t know about anything going on in any other file.
- It also doesn’t support `open` or `final` for the moment, mostly because it’s a bit more work and just ship it already, and partly because I sort of feel those notations should require a bit more forethought when planning a framework. 

### To install:
I'll get it on the Mac app store once I've used it for a while longer. In the meantime: 

- Download the Xcode project
- Archive the Mac app target
- Export the created archive using the option `Export App without resigning` to use locally
- Launch the app
- The extension will now be available in System Preferences, under the Extensions pane, listed as an Xcode Source Editor extension. Activate!
- After an Xcode restart, find it under the Editor menu - it only works on selected Swift code 
- For even more radness, you can bind keyboard shortcuts to the menu commands

### If you find a bug:
- Did I forget to parse a keyword? Something even more annoying? Please create an issue or get in touch on twitter: [@zoejessica](https://twitter.com/zoejessica)
