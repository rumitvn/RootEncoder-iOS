//
//  BaseFilterRender.swift
//  encoder
//
//  Created by Pedro  on 4/11/23.
//

import Foundation
import CoreImage

public protocol BaseFilterRender {
    func initialize()
    func draw(image: CIImage) -> CIImage
    func release()
}
