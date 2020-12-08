//
//  GrowViews.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/7/20.
//

import SwiftUI


extension Grow {
    struct Image: View {
       let title: String
       
       var body: some View {
         let symbol =
           SwiftUI.Image(title: title)
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
  init?(title: String) {
    guard
      let character = title.first,
      case let symbolName = "\(character.lowercased()).square",
      UIImage(systemName: symbolName) != nil
    else {
      return nil
    }
    self.init(systemName: symbolName)
  }
}



struct Grow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Grow.Image(title:"cat")
        }
    }
}
