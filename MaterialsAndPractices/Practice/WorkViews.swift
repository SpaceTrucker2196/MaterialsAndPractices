//
//  PracticeViews.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/10/20.
//

import SwiftUI

extension Work {
    struct Image: View {
       let practiceTitle: String
       
       var body: some View {
         let symbol =
           SwiftUI.Image(materialTitle: practiceTitle)
           ?? .init(systemName: "figure.walk.diamond")
        
        VStack(alignment: .center) {
            symbol
              .resizable()
              .scaledToFit()
              .frame(width: 80, height: 80)
              .font(Font.title.weight(.light))
              .foregroundColor(Color("OrganicPracticeColor"))
            
            Text(practiceTitle).font(Font.caption.weight(.medium))
                .font(.callout)
                .foregroundColor(Color("OrganicPracticeColor"))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.all, 0.0)
                .frame(width: 66.0)
        }
       }
     }
}

extension Image {
  init?(practiceTitle: String) {
    guard
      let character = practiceTitle.first,
      case let symbolName = "\(character.lowercased()).square",
      UIImage(systemName: symbolName) != nil
    else {
      return nil
    }
    self.init(systemName: symbolName)
  }
}


struct PracticeViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Work.Image(practiceTitle:"test")
            Work.Image(practiceTitle:"")
        }
    }
}
