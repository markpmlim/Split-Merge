//
//  Extensions.swift
//  SplitMerge
//
//  Created by Mark Lim Pak Mun on 09/11/2020.
//  Copyright © 2020 Mark Lim Pak Mun. All rights reserved.
//

extension BinaryInteger {
    var isPowerOfTwo: Bool {
        return (self > 0) && (self & (self-1) == 0)
    }
    
    func isMultiple(of other: Self) -> Bool {
        let remainder = self % other
        return remainder == 0
    }
    
}
