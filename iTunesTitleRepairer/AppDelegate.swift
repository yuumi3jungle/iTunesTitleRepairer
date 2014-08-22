//
//  AppDelegate.swift
//  iTunesTitleRepairer
//
//  Created by Yuumi Yoshida on 2014/08/14.
//  Copyright (c) 2014年 Yuumi Yoshida. All rights reserved.
//

import Cocoa


class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate {
                            
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var albumTitle: NSTextField!
    @IBOutlet weak var songTable: NSTableView!
    @IBOutlet      var newTitleText: NSTextView!

    var trackIds: [Int] = []
    var iTunes: ITunesLibrary = ITunesLibrary()
    
    let NewFilesFolder = NSHomeDirectory() + "/Desktop"
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        performBlock(0.1) { self.openLibrary(ITunesLibrary.XmlFilePath()) }
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
    }

    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        return trackIds.count
    }
    
    
    func tableView(tableView: NSTableView!, objectValueForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject! {
        if tableColumn.identifier == "SequenceColumn" {
            return row + 1
        } else {
            return iTunes.songTitle(trackIds[row])
        }
    }

    @IBAction func openDocument(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        if openPanel.runModal() == NSOKButton && openPanel.URLs.count == 1 {
            openLibrary((openPanel.URLs[0] as NSURL).path!)
        }
    }

    @IBAction func saveDocument(sender: AnyObject) {
        if let err = iTunes.save(NewFilesFolder) {
             showErrorAlert(err)
        }
    }
    
    @IBAction func searchPushed(sender: AnyObject) {
        trackIds = iTunes.searchAlubm(albumTitle.stringValue)
        songTable.reloadData()
    }

    @IBAction func replacePushed(sender: AnyObject) {
        let titles = ITunesLibrary.parse(newTitleText.string)
        if titles.count == 0  { return }

        if let err = iTunes.replaceTiles(trackIds, titles) {
            showErrorAlert(err)
        } else {
            songTable.reloadData()
            newTitleText.string = ""
        }
    }
    
    private func openLibrary(path: String) {
        if let err = iTunes.load(path) {
            showErrorAlert(err)
        } else {
            newTitleText.string = ""
            albumTitle.stringValue = ""
            albumTitle.enabled = true
            trackIds = []
            songTable.reloadData()
        }
    }
    
    private func showErrorAlert(error: NSError!) {
        var alert = NSAlert(error: error)
        if alert.runModal() == NSAlertFirstButtonReturn {
            // NOP
        }
    }

    private func performBlock(deley: Double, _ closure: () -> ()) {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, Int64(deley * Double(NSEC_PER_SEC))),
            dispatch_get_main_queue(),
            closure)
    }

}

