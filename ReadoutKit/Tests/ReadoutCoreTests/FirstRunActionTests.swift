import Testing

@testable import ReadoutCore

@Suite struct FirstRunActionTests {
    final class Store {
        var done = false
    }

    struct TestFailure: Error {}

    private func action(_ store: Store) -> FirstRunAction {
        FirstRunAction(isDone: { store.done }, markDone: { store.done = true })
    }

    @Test func runsOnFirstLaunch() {
        let store = Store()
        var runs = 0
        action(store).perform { runs += 1 }
        #expect(runs == 1)
        #expect(store.done)
    }

    @Test func neverRunsAgainAfterTheFirstLaunch() {
        let store = Store()
        var runs = 0
        action(store).perform { runs += 1 }
        action(store).perform { runs += 1 }
        #expect(runs == 1)
    }

    @Test func aFailedAttemptIsStillMarkedDoneSoTheUsersLaterChoiceSticks() {
        let store = Store()
        var runs = 0
        action(store).perform {
            runs += 1
            throw TestFailure()
        }
        action(store).perform { runs += 1 }
        #expect(runs == 1)
        #expect(store.done)
    }
}
