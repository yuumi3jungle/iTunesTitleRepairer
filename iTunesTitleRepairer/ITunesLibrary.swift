//
//  ITunesLibrary.swift
//  iTunesTitleRepairer
//
//  Created by Yuumi Yoshida on 2014/08/15.
//  Copyright (c) 2014年 Yuumi Yoshida. All rights reserved.
//

import Cocoa

struct MpegFileTitle : Printable {
    let path: String
    let title: String
    var description: String { get {return "path: \(self.path) title: \(self.title)"} }  // Not work as "Swift Standard Library Reference"
}

typealias TrackId = Int


class ITunesLibrary: NSObject {
    class var LibraryXmlFileName: String { get { return "iTunes Music Library.xml" } }
    class var MpegTitleFileName: String { get { return "MpegTitleList.txt" } }
    
    var libaryDict: NSMutableDictionary = [:]
    var mpegTitleList: [MpegFileTitle] = []

    class func XmlFilePath() -> String {
        return NSHomeDirectory() + "/Music/iTunes/iTunes Music Library.xml"
    }
    
    func load(libraryXmlPath: String) -> NSError? {
        var error:NSError?;

        let data = NSData.dataWithContentsOfFile(libraryXmlPath, options: nil, error: &error)
        if data == nil {
            return error
        }
        let plist = NSPropertyListSerialization.propertyListWithData(data,
            options: 2, format: nil, error: &error) as NSMutableDictionary!
        if plist == nil {
            return error
        }
        libaryDict = plist
        mpegTitleList = []
        return nil
    }
    
    func save(saveFolderPath: String) -> NSError? {
        var error:NSError?;

        let data = NSPropertyListSerialization.dataWithPropertyList(libaryDict,
            format: NSPropertyListFormat.XMLFormat_v1_0, options: 0, error: &error)
        if data == nil {
            return error
        }
        if !data.writeToFile(saveFolderPath.stringByAppendingPathComponent(ITunesLibrary.LibraryXmlFileName),
            options: NSDataWritingOptions.AtomicWrite, error: &error) {
            return error
        }

        var mpegTitlesFile = "\n".join(mpegTitleList.map({"\($0.path)\t\($0.title)"})) + "\n"
        if !mpegTitlesFile.writeToFile(saveFolderPath.stringByAppendingPathComponent(ITunesLibrary.MpegTitleFileName),
            atomically: true, encoding: NSUTF8StringEncoding, error: &error) {
            return error
        }

        return nil
    }
    
    func searchAlubm(title: String) -> [TrackId] {
        var trackIds : Array<TrackId> = []
        let tracks = libaryDict["Tracks"] as NSDictionary
        for (key, dict) in tracks {
            if (dict["Album"] as String?) == title {
                trackIds.append((key as String).toInt()!)
            }
        }
        trackIds.sort { $0 < $1 }
        return trackIds
    }
    
    func songTitle(id: TrackId) -> String {
        let tracks = libaryDict["Tracks"] as NSDictionary
        let track = tracks[String(id)] as NSDictionary
        return track["Name"] as String
    }

    class func parse(titlesChunk: String) -> [String] {
        var titles: [String] = []
        let regex = NSRegularExpression.regularExpressionWithPattern("\\d+\\.\\s*(.*?)(\\s*試聴する)?$", options: nil, error: nil)
        
        for line in titlesChunk.componentsSeparatedByString("\n") {
            if var matches = regex?.firstMatchInString(line, options: nil, range: NSMakeRange(0, countElements(line))) {
                titles.append((line as NSString).substringWithRange(matches.rangeAtIndex(1)))
            }
        }
        
        return titles
    }
    
    func replaceTiles(ids: [TrackId], _ titles: [String]) -> NSError? {
        if ids.count != titles.count {
            return NSError.errorWithDomain("The number of titles is not the same as the number of tracks", code: 10001, userInfo:  nil)
        }
        let tracks = libaryDict["Tracks"] as NSDictionary

        for id in ids {
            if tracks[String(id)] == nil {
                return NSError.errorWithDomain("TrackId \(id) not found", code: 10002, userInfo:  nil)
            }
        }

        for var i = 0; i < ids.count; i++ {
            var track = tracks[String(ids[i])] as NSMutableDictionary
            track["Name"] = titles[i]
            mpegTitleList.append(MpegFileTitle(path: NSURL.URLWithString(track["Location"] as String).path!, title: titles[i]))
        }
        
        return nil
    }
}
