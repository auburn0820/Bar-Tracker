//
//  ContentView.swift
//  Bar Tracker
//
//  Created by 피수영 on 2021/06/16.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VideoSelectView()
                .navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
