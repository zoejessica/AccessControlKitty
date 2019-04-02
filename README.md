# AccessControlKitty
Xcode extension to change the access control level of Swift code selection

[Download from the Mac App Store](https://itunes.apple.com/us/app/accesscontrolkitty/id1450391666?mt=12)

### Features
- Works on selected Swift code to switch between `public`, `private`, `fileprivate`, `internal` or no access control modifier. Choose an option from the new Access Level of Selection item at the bottom of Xcode's Editor menu:
- Increment access levels in selected code. So, `private` and `fileprivate` code becomes `internal`, `internal` becomes `public`, and any `public` code stays as is. 
- Decrement access levels. `private` code stays as is, `fileprivate` and `internal` become `private`, and `public` code becomes `internal`. 
- Create API – changes all `internal` code to `public`, exposing it as API for your framework
- Remove API – similarly, changes all `public` code to be `internal`, removing its visibility as API
- Set all appropriate access modifiers to one level
- Remove access notation entirely
- Setters with overriden access levels (for example, `private(set) internal var`) are treated separately: when incrementing/decrementing access, or making/removing API, overridden setters maintain their current access level. If the underlying entity ends up with the same access level as the overriden setter, the explicit override is removed. When setting code to a single access level, the explicit setter override is removed so the entire entity is set to the desired level. 

### Caveats
- It’s not particularly smart, so for example it doesn’t know if a function can’t be made public because it relies on an internal type. Or if a subclass can't be made public because its superclass isn't public. And it certainly can't reason about anything going on in any other file. It just operates on the bits of selected Swift code that *could*, grammatically speaking, have an access control modifier. 
- It also doesn’t support `open` or `final` for the moment, mostly because it’s a bit more work and just ship it already, and partly because I sort of feel those notations should require a bit more forethought when planning a framework. 
- **Next on the list are the (new I think) warnings in Swift 5 about redundant `public` declarations of top level members in `public` extensions. Work in progress, to come shortly 😅**

### To install:
[Available to download now on the Mac App Store](https://itunes.apple.com/us/app/accesscontrolkitty/id1450391666?mt=12).

For the latest version:  

- Download the Xcode project
- Archive the Mac app target
- From the Organizer window, which should open automatically, click `Distribute` and export the created archive using the option `Copy` to use locally. Save wherever you like.
- Launch the app
- The extension will now be available in System Preferences, under the Extensions pane, listed as an Xcode Source Editor extension. Activate!
- After an Xcode restart, find it under the Editor menu - it only works on selected Swift code 
- For even more radness, you can bind keyboard shortcuts to the menu commands

### Bugs & feedback:
- Please [create an issue](https://github.com/zoejessica/AccessControlKitty/issues/new) or tweet [@zoejessica](https://twitter.com/zoejessica).
