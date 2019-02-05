# AccessControlKitty
Xcode extension to change the access control level of Swift code selection

### Features
- Works on selected Swift code to switch between `public`, `private`, `fileprivate`, `internal` or no access control modifier. Choose an option from the new Access Level of Selection item at the bottom of Xcode's Editor menu:
- Increment access levels in selected code. So, `private` and `fileprivate` code becomes `internal`, `internal` becomes `public`, and any `public` code stays as is. 
- Decrement access levels. `private` code stays as is, `fileprivate` and `internal` become `private`, and `public` code becomes `internal`. 
- Create API – changes all `internal` code to `public`, exposing it as API for your framework
- Remove API – similarly, changes all `public` code to be `internal`, removing its visibility as API
- Set all appropriate access modifiers to one level
- Remove access notation entirely

### Unfeatures
- It’s not particularly smart, so for example it doesn’t know if a function can’t be made public because it relies on an internal type. Or if a subclass can't be made public because its superclass isn't public. And it certainly can't reason about anything going on in any other file. It just takes into account which bits of Swift code *could*, all other things being equal, have an access control modifier. 
- It also doesn’t support `open` or `final` for the moment, mostly because it’s a bit more work and just ship it already, and partly because I sort of feel those notations should require a bit more forethought when planning a framework. 

### To install:
Available soon on the Mac App Store, free as in beer. In the meantime: 

- Download the Xcode project
- Archive the Mac app target
- From the Organizer window, which should open automatically, click `Distribute` and export the created archive using the option `Copy` to use locally. Save wherever you like.
- Launch the app
- The extension will now be available in System Preferences, under the Extensions pane, listed as an Xcode Source Editor extension. Activate!
- After an Xcode restart, find it under the Editor menu - it only works on selected Swift code 
- For even more radness, you can bind keyboard shortcuts to the menu commands

### If you find a bug:
- Did I forget to parse a keyword? Something even more annoying? Please create an issue or get in touch on twitter: [@zoejessica](https://twitter.com/zoejessica)
