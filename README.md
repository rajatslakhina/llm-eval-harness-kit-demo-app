# llm-eval-harness-kit-demo-app

**A merge gate for an LLM feature, running on an iPhone — and you can make it fail three different ways.**

This is the runnable companion to
[**llm-eval-harness-kit**](https://github.com/rajatslakhina/llm-eval-harness-kit).
It consumes that library as a **remote Swift package dependency** by its GitHub URL, exactly the
way any external consumer would — there is no local path reference and no copy of the source in
this repository.

The app itself is 20 lines. Everything interesting lives in the package.

---

## Why this matters

Teams shipping LLM-backed features cannot write `XCTAssertEqual` against a model, so eval either
becomes a manual pre-release ritual (which dies on contact with a release train) or an
LLM-as-judge suite that costs money and flakes on every PR.

This demo shows the third option running on device: a **hermetic** suite that replays a committed
transcript cache, scores it with deterministic rubrics, and — the part most eval tooling skips —
**attributes** a regression to the person who caused it.

Three controls, three failure modes you can reproduce by hand:

| Control | What happens | What the gate says |
|---|---|---|
| **Prompt revision → r2** | A "harmless copy edit" drops the refusal clause from the template | `refusal-01` → **PROMPT REGRESSION**; the `refusal` slice collapses and fails its floor |
| **Provider build → July** | Nobody touched the prompt; the provider now answers a tool-call case in prose | `toolcall-02` → **MODEL DRIFT**, old build → new build named explicitly |
| **Tight cost budget** | Every *quality* condition passes and the run still goes red | Gate fails on **cost**, because spend is a merge condition, not a dashboard metric |

And in both regression scenarios the **global mean stays above its floor** (0.81 against a 0.70
floor) while the failing slice drops under its own, stricter floor (0.80). That gap is the point:
a healthy average does not rescue a collapsed slice, and a gate that only checks the aggregate
would have waved both of them through.

`summary-03` is deliberately unstable across its recorded history, so it comes back
**quarantined as flaky** — reported loudly, not blocking. A gate that blocks on noise gets
switched off within a month, and a gate nobody runs protects nothing.

---

## Screenshots

**None yet — the app has not been launched on a Simulator.** Rather than ship a mockup or a
description dressed up as evidence, this section stays empty until there is a real capture of the
app running. See [Verification](#verification) for exactly what has and has not been executed.

---

## How to run it

1. Clone this repository.
2. Open **`Demo.xcodeproj`** in Xcode 16.0 or later (project format `objectVersion = 56`).
3. Wait for Xcode to resolve the remote package
   `https://github.com/rajatslakhina/llm-eval-harness-kit.git` (branch `main`).
4. Select the **`Demo`** scheme and any iOS Simulator (iOS 17.0+).
5. **Build & Run** (⌘R).
6. Tap **Run eval suite**, then change the prompt revision or the provider build and run it again.

No API keys, no network calls, no configuration. The demo records its fixture transcripts into an
in-memory cache on first run and replays them afterwards — watch the *upstream calls* counter stop
rising while *cached transcripts* stays flat.

---

## How this repo is wired

```
Demo.xcodeproj
└── XCRemoteSwiftPackageReference
    repositoryURL = https://github.com/rajatslakhina/llm-eval-harness-kit.git
    requirement   = { kind = branch; branch = main; }
        ├── product: EvalHarness      (core, Foundation only)
        └── product: EvalHarnessUI    (SwiftUI dashboard)

Demo/DemoApp.swift    @main App → EvalDashboardView()
```

The split is deliberate. The library repository contains **no app target and no executable
product** — it is a library anyone can depend on. This repository contains the runnable app and
nothing else. If the demo needed a pile of glue code to look good, the library would not actually
be reusable.

**Rejected alternative:** a single repository with the app target sitting beside `Package.swift`.
That is simpler to ship and keeps everything in one place — but the app can then reach into
library internals through the same build graph, and nothing ever proves the package is consumable
from outside. The split is what makes "this library works for other people" a fact rather than an
assertion.

**What the split costs:** two repositories to keep in sync, and this project pins
`requirement = { kind = branch; branch = main; }` rather than a version tag — so a breaking change
pushed to the library's `main` breaks this demo until the package is re-resolved. That is the
right trade for a portfolio demo, where always tracking the latest library is the point; a
production consumer should pin an exact version instead.

---

## Verification

Being specific about this, because a README that overclaims is worth less than one that says
nothing.

**What was verified.** The library this app depends on is green on CI:
`swift build -v` and `swift test -v` both pass on a `macos-latest` GitHub Actions runner
([workflow](https://github.com/rajatslakhina/llm-eval-harness-kit/actions/workflows/ci.yml)),
including an `EvalGateCITests` case that runs the eval gate itself and publishes its report to the
job summary. Every rubric score, verdict and gate outcome quoted in the table above is asserted by
those tests, not estimated. `Demo.xcodeproj` was checked for structural soundness (balanced
delimiters, every referenced UUID defined, remote package reference and product dependencies wired
into both `packageProductDependencies` and the Frameworks build phase), and `DemoApp.swift` was
scanned for crash-prone patterns.

**What was not verified.** This iOS app target has **not been compiled and has not been launched
on a Simulator**, and no screenshots exist. The run was attempted during an unattended scheduled
build and could not be completed: automated control of Xcode and Simulator on the build machine
was unavailable for the duration of the run. So treat "it builds and runs" as unproven here — the
package it depends on is verified, the app wrapper around it is not.

---

## The library

[**rajatslakhina/llm-eval-harness-kit**](https://github.com/rajatslakhina/llm-eval-harness-kit) —
golden sets, content-addressed transcript replay, weighted rubrics, self-consistent
LLM-as-judge, actor-isolated budget accounting, bounded-concurrency runner, regression
classifier, per-slice gate, and on-device-vs-cloud capability comparison.
