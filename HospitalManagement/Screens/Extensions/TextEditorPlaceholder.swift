import SwiftUI

//// MARK: - TextEditor Placeholder Extension
//extension View {
//    func placeholder<Content: View>(
//        when shouldShow: Bool,
//        alignment: Alignment = .leading,
//        @ViewBuilder then: () -> Content
//    ) -> some View {
//        ZStack(alignment: alignment) {
//            then()
//                .opacity(shouldShow ? 1 : 0)
//            
//            self
//        }
//    }
//    
//    func placeholder(
//        _ text: String,
//        when shouldShow: Bool,
//        alignment: Alignment = .leading
//    ) -> some View {
//        placeholder(when: shouldShow, alignment: alignment) {
//            Text(text)
//                .foregroundColor(.gray)
//        }
//    }
//} 
