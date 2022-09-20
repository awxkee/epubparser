//
//  EPUB+Errors.swift
//  Document Reader
//
//  Created by Radzivon Bartoshyk on 24/04/2022.
//

import Foundation

public struct EPUBCoverNotAvailableError: LocalizedError {
    public var errorDescription: String? {
        "EPUB covert is not available"
    }
}
public struct EPUBTitleNotAvailableError: LocalizedError {
    public var errorDescription: String? {
        "Failed to retreive EPUB book title"
    }
}
public struct EPUBAuthorNotAvailableError: LocalizedError {
    public var errorDescription: String? {
        "Failed to retreive EPUB book author"
    }
}
public struct EPUBBookNotAvailableError: LocalizedError {
    public var errorDescription: String? {
        "File with book is not avialable"
    }
}
public struct EPUBPathEmptyError: Error, Equatable {
    public var errorDescription: String? {
        "Path with required file is not available"
    }
}
public struct EPUBFailedToBuiltHTMLError: LocalizedError {
    public var errorDescription: String? {
        "Error while building final book document"
    }
}
public struct EPUBInvalidImageError: LocalizedError {
    let path: String

    public var errorDescription: String? {
        "Image for EPUB is not available"
    }
}
public struct InvalidPackageURLError: LocalizedError {
    public var errorDescription: String? {
        return "At first EPUB book must bo opened"
    }
}
public struct InvalidEpubContentsError: Error {
    public var errorDescription: String? {
        return "Invalid pages count in EPUB"
    }
}
public struct EPUBInvalidArchiveError: LocalizedError {
    public var errorDescription: String? {
        return "Invalid EPUB archive"
    }
}
