//
//  FRSmil.swift
//  Pods
//
//  Created by Kevin Jantzer on 12/30/15.
//
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// Media Overlay Documentation
// http://www.idpf.org/accessibility/guidelines/content/overlays/overview.php#mo005-samp


class EpubSmilElement: NSObject {
    var name: String // the name of the tag: <seq>, <par>, <text>, <audio>
    var attributes: [String: String]!
    var children: [EpubSmilElement]

    init(name: String, attributes: [String:String]!) {
        self.name = name
        self.attributes = attributes
        self.children = [EpubSmilElement]()
    }

    // MARK: - Element attributes

    func getId() -> String! {
        return getAttribute("id")
    }

    func getSrc() -> String! {
        return getAttribute("src")
    }

    /**
     Returns array of Strings if `epub:type` attribute is set. An array is returned as there can be multiple types specified, seperated by a whitespace
     */
    func getType() -> [String]! {
        let type = getAttribute("epub:type", defaultVal: "")
        return type!.components(separatedBy: " ")
    }

    /**
     Use to determine if this element matches a given type

     **Example**

     epub:type="bodymatter chapter"
     isType("bodymatter") -> true
     */
    func isType(_ aType:String) -> Bool {
        return getType().contains(aType)
    }

    func getAttribute(_ name: String, defaultVal: String!) -> String! {
        return attributes[name] != nil ? attributes[name] : defaultVal;
    }

    func getAttribute(_ name: String ) -> String! {
        return getAttribute(name, defaultVal: nil)
    }

    // MARK: - Retrieving children elements

    // if <par> tag, a <text> is required (http://www.idpf.org/epub/301/spec/epub-mediaoverlays.html#sec-smil-par-elem)
    func textElement() -> EpubSmilElement! {
        return childWithName("text")
    }

    func audioElement() -> EpubSmilElement! {
        return childWithName("audio")
    }

    func videoElement() -> EpubSmilElement! {
        return childWithName("video")
    }

    func childWithName(_ name:String) -> EpubSmilElement! {
        for el in children {
            if( el.name == name ){
                return el
            }
        }
        return nil;
    }

    func childrenWithNames(_ name:[String]) -> [EpubSmilElement]! {
        var matched = [EpubSmilElement]()
        for el in children {
            if( name.contains(el.name) ){
                matched.append(el)
            }
        }
        return matched;
    }

    func childrenWithName(_ name:String) -> [EpubSmilElement]! {
        return childrenWithNames([name])
    }

    // MARK: - Audio clip info

    func clipBegin() -> Double {
        let val = audioElement().getAttribute("clipBegin", defaultVal: "")
        return val!.clockTimeToSeconds()
    }

    func clipEnd() -> Double {
        let val = audioElement().getAttribute("clipEnd", defaultVal: "")
        return val!.clockTimeToSeconds()
    }
}
