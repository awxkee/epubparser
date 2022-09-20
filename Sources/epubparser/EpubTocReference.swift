//
//  FRTocReference.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 06/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

open class EpubTocReference: NSObject {
    var children: [EpubTocReference]!

    public var title: String!
    public var resource: EpubResource?
    public var fragmentID: String?
    
    convenience init(title: String, resource: EpubResource?, fragmentID: String = "") {
        self.init(title: title, resource: resource, fragmentID: fragmentID, children: [EpubTocReference]())
    }

    init(title: String, resource: EpubResource?, fragmentID: String, children: [EpubTocReference]) {
        self.resource = resource
        self.title = title
        self.fragmentID = fragmentID
        self.children = children
    }
}

// MARK: Equatable

func ==(lhs: EpubTocReference, rhs: EpubTocReference) -> Bool {
    return lhs.title == rhs.title && lhs.fragmentID == rhs.fragmentID
}
