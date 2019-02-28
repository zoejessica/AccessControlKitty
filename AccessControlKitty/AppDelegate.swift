//
//  AppDelegate.swift
//  AccessControlKitty
//
//  Created by Zoe Smith on 4/28/18.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true 
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func openAGithubIssue(_ sender: Any) {
        let url = URL(string: "https://github.com/zoejessica/AccessControlKitty/issues/new")!
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func about(_ sender: Any) {
        let url = URL(string: "https://hotbeverage.software/accesscontrolkitty")!
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func feedback(_ sender: Any) {
        let url = URL(string: "https://twitter.com/zoejessica")!
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func githubProject(_ sender: Any) {
        let url = URL(string: "https://github.com/zoejessica/AccessControlKitty")!
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func readme(_ sender: Any) {
        let url = URL(string: "https://github.com/zoejessica/AccessControlKitty/blob/master/README.md")!
        NSWorkspace.shared.open(url)
    }
}
