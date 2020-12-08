//
//  MaterialViews.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/7/20.
//

import SwiftUI

extension Material {
    struct Image: View {
       let title: String
       
       var body: some View {
         let symbol =
           SwiftUI.Image(materialTitle: title)
           ?? .init(systemName: "book")

         symbol
           .resizable()
           .scaledToFit()
           .frame(width: 80, height: 80)
           .font(Font.title.weight(.light))
           .foregroundColor(.green)
       }
     }
}

extension Image {
  init?(materialTitle: String) {
    guard
      let character = materialTitle.first,
      case let symbolName = "\(character.lowercased()).square",
      UIImage(systemName: symbolName) != nil
    else {
      return nil
    }
    self.init(systemName: symbolName)
  }
}



struct Material_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Grow.Image(title:"cat")
        }
    }
}
