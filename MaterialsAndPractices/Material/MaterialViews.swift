//
//  MaterialViews.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/7/20.
//

import SwiftUI

extension Material {
    struct Image: View {
       let materialTitle: String
       
       var body: some View {
         let symbol =
           SwiftUI.Image(materialTitle: materialTitle)
           ?? .init(systemName: "book")
        
        VStack {
            symbol
              .resizable()
              .scaledToFit()
              .frame(width: 80, height: 80)
              .font(Font.title.weight(.light))
              .foregroundColor(Color("OrganicMaterialColor"))
            
            Text(materialTitle).font(Font.caption.weight(.medium))
                .font(.callout)
                .foregroundColor(Color("OrganicMaterialColor"))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.all, 0.0)
                .frame(width: 66.0)
                .border(Color("OrganicMaterialColor"), width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
        }
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
            Material.Image(materialTitle:"test")
        }
    }
}
