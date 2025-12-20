//
//  LoginView.swift
//  GoogleCalendarAPIDemo
//
//  Created by Goel, Pratik on 20/11/22.
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject var loginViewModel: AuthenticationViewModel

    var body: some View {
        VStack {
            LottieView(name: "calendar_home", loopMode: .loop)
            Spacer()
            Button(action: loginViewModel.signIn) {
                Text("Sign in")
            }.padding()
        }
    }
}
