//
//  AccessControlError.swift
//  AccessControlKittyExtension
//
//  Created by Zoe Smith on 7/4/19.
//  Copyright © 2019 Hot Beverage. All rights reserved.
//

import Foundation

extension AccessControlCommand {
    
    public enum AccessControlError: LocalizedError, CustomNSError {
        case unsupportedContentType
        case noSelection
        
        var localizedDescription: String {
            switch self {
            case .unsupportedContentType: return "AccessControlKitty only works on Swift code."
            case .noSelection: return "AccessControlKitty needs a selection to work on."
            }
        }
        
        public var errorUserInfo: [String: Any] {
            return [NSLocalizedDescriptionKey: localizedDescription]
        }
    }
}
