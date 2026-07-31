import SwiftUI
import EvalHarnessUI

/// The entire app.
///
/// Everything on screen — the golden set, the transcript cache, the scoring, the
/// regression classifier and the gate — lives in the `llm-eval-harness-kit`
/// package, which this project consumes as a **remote** Swift package
/// dependency by its GitHub URL, exactly the way any external consumer would.
///
/// The app deliberately adds no logic of its own. If a demo needs a pile of glue
/// code to look good, the library is not actually reusable.
@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            EvalDashboardView()
        }
    }
}
