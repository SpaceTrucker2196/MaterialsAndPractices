//
//  GrowViews.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/7/20.
//

import SwiftUI


extension Grow {
    struct Image: View {
       let grow: Grow
       
       var body: some View {
         let symbol =
           SwiftUI.Image(grow: grow)
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
  init?(grow: Grow) {
    guard
      let character = grow.title?.first,
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
            Grow.Image(grow:Grow(context:PersistenceController.preview.container.viewContext))
        }
    }
}
