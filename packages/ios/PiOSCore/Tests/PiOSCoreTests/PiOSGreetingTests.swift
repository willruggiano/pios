import PiOSCore
import Testing

struct PiOSGreetingTests {
  @Test
  func qualificationGreetingIsStable() {
    #expect(PiOSGreeting.text == "Hello, Pi")
  }
}
