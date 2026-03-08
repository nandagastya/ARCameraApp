//
//  RootView.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                SplashView()
            } else if authViewModel.isAuthenticated {
                MainCameraView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authViewModel.isAuthenticated)
    }
}

#Preview {
    RootView()
}
