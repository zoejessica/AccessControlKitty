# AccessControlKitty
Xcode extension to change the access control level of Swift code selection

### Features
- Change or remove access control level of the currently selected Swift code
- Supports `public`, `private`, `fileprivate`, `internal` and removing any annotation. 

![Demo of changing access level](https://media.giphy.com/media/TFyv6GmLguWLonRAnn/giphy.gif)

### Unfeatures
- It’s not particularly smart, so for example it doesn’t know if a function /can’t/ be made public because it relies on an internal type.  And it certainly doesn’t know about anything going on in any other file.
- It also doesn’t support `open` or `final` for the moment, mostly because it’s a bit more work and just ship it already, and partly because I sort of feel those notations should require a bit more forethought when planning a framework. 

### To install:
- Download the Xcode project
- Archive the Mac app target
- Export the created archive using the option `Export App without resigning` to use locally
- Launch the app
- The extension will now be available in System Preferences, under the Extensions pane, listed as an Xcode Source Editor extension

### If you find a bug:
- I probably forgot to parse a keyword! Please create an issue or get in touch on twitter: [@zoejessica](https://twitter.com/zoejessica)
