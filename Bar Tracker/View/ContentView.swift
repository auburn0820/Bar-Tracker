//
//  ContentView.swift
//  Bar Tracker
//
//  Created by νΌμμ on 2021/06/16.
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
