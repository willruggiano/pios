//
//  ContentView.swift
//  PiOS
//
//  Created by runner on 8/17/26.
//

import PiOSCore
import SwiftUI

public enum PiOSAppContent {
  public static let greeting = PiOSGreeting.text
}

struct ContentView: View {
  var body: some View {
    Text(PiOSAppContent.greeting)
  }
}

#Preview {
  ContentView()
}
