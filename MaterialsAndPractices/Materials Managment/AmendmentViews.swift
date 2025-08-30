//
//  MaterialViews.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/7/20.
//

import SwiftUI

extension CropAmendment {
    struct Image: View {
       let amendmentTitle: String
       
       var body: some View {
         let symbol =
           SwiftUI.Image(materialTitle: amendmentTitle)
           ?? .init(systemName: "leaf.arrow.triangle.circlepath")
        
        VStack(alignment: .center) {
            symbol
              .resizable()
              .scaledToFit()
              .frame(width: 80, height: 80)
              .font(Font.title.weight(.light))
              .foregroundColor(Color("OrganicMaterialColor"))
            
            Text(amendmentTitle).font(Font.caption.weight(.medium))
                .font(.callout)
                .foregroundColor(Color("OrganicMaterialColor"))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.all, 0.0)
                .frame(width: 66.0)
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
            CropAmendment.Image(amendmentTitle:"test")
        }
    }
}
