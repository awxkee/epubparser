//
//  FRSmils.swift
//  Pods
//
//  Created by Kevin Jantzer on 12/30/15.
//
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct EpubSmilFile {
    var resource: EpubResource
    var data = [EpubSmilElement]()

    init(resource: EpubResource){
        self.resource = resource;
    }

    // MARK: - shortcuts

    func ID() -> String {
        return self.resource.id;
    }

    func href() -> String {
        return self.resource.href;
    }

    // MARK: - data methods

    /**
     Returns a smil <par> tag which contains info about parallel audio and text to be played
     */
    func parallelAudioForFragment(_ fragment: String!) -> EpubSmilElement! {
        return findParElement(forTextSrc: fragment, inData: data)
    }

    fileprivate func findParElement(forTextSrc src:String!, inData _data:[EpubSmilElement]) -> EpubSmilElement! {
        for el in _data {

            // if its a <par> (parallel) element and has a <text> node with the matching fragment
            if( el.name == "par" && (src == nil || el.textElement().attributes["src"]?.contains(src) != false ) ){
                return el

                // if its a <seq> (sequence) element, it should have children (<par>)
            }else if el.name == "seq" && el.children.count > 0 {
                let parEl = findParElement(forTextSrc: src, inData: el.children)
                if parEl != nil { return parEl }
            }
        }
        return nil
    }

    /**
     Returns a smil <par> element after the given fragment
     */
    func nextParallelAudioForFragment(_ fragment: String) -> EpubSmilElement! {
        return findNextParElement(forTextSrc: fragment, inData: data)
    }

    fileprivate func findNextParElement(forTextSrc src:String!, inData _data:[EpubSmilElement]) -> EpubSmilElement! {
        var foundPrev = false
        for el in _data {

            if foundPrev { return el }

            // if its a <par> (parallel) element and has a <text> node with the matching fragment
            if( el.name == "par" && (src == nil || el.textElement().attributes["src"]?.contains(src) != false) ){
                foundPrev = true

                // if its a <seq> (sequence) element, it should have children (<par>)
            }else if el.name == "seq" && el.children.count > 0 {
                let parEl = findNextParElement(forTextSrc: src, inData: el.children)
                if parEl != nil { return parEl }
            }
        }
        return nil
    }


    func childWithName(_ name:String) -> EpubSmilElement! {
        for el in data {
            if( el.name == name ){
                return el
            }
        }
        return nil;
    }

    func childrenWithNames(_ name:[String]) -> [EpubSmilElement]! {
        var matched = [EpubSmilElement]()
        for el in data {
            if( name.contains(el.name) ){
                matched.append(el)
            }
        }
        return matched;
    }

    func childrenWithName(_ name:String) -> [EpubSmilElement]! {
        return childrenWithNames([name])
    }
}

/**
 Holds array of `FRSmilFile`
 */
class EpubSmils: NSObject {
    var basePath            : String!
    var smils               = [String: EpubSmilFile]()

    /**
     Adds a smil to the smils.
     */
    func add(_ smil: EpubSmilFile) {
        self.smils[smil.resource.href] = smil
    }

    /**
     Gets the resource with the given href.
     */
    func findByHref(_ href: String) -> EpubSmilFile? {
        for smil in smils.values {
            if smil.resource.href == href {
                return smil
            }
        }
        return nil
    }

    /**
     Gets the resource with the given id.
     */
    func findById(_ ID: String) -> EpubSmilFile? {
        for smil in smils.values {
            if smil.resource.id == ID {
                return smil
            }
        }
        return nil
    }
}
