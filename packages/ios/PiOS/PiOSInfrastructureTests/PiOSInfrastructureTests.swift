//
//  PiOSInfrastructureTests.swift
//  PiOSInfrastructureTests
//
//  Created by runner on 8/17/26.
//

import PiOS
import Testing

struct PiOSInfrastructureTests {
  @MainActor
  @Test
  func appUsesPiOSCoreGreeting() {
    #expect(PiOSAppContent.greeting == "Hello, Pi")
  }
}
