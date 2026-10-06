# CI / release recommendation (CP6)

Advisory only — no release CI was rewritten in this task.

## Recommended future release certification shape

```text
Nift release certification

1.  Nift core internal tests            (implementation-local)
2.  nift-regression-suite               (Nift semantics + package machinery, fixtures)
3.  packages-regression-suite           (official ecosystem compatibility, real packages)
4.  package-repository CI               (independently authoritative per package)
```

Interpretation guide for a red result:

- Nift core / `nift-regression-suite` red → likely a Nift regression.
- `packages-regression-suite` red → ecosystem/package compatibility regression.
- individual package CI red → package-specific defect.

`packages-regression-suite` is a candidate Nift release gate, but it must not be
folded back into the core historical contract corpus. It is wired to accept an
arbitrary supplied Nift binary, so a future matrix can cover "latest supported
release" and "current development" without hard-coding any version.

## Not done here (deliberately)

- No GitHub workflow was added or rewritten for `packages-regression-suite`
  (suitable for CI later; the runner is deterministic and temp-workspace-isolated).
- No multi-version matrix was built.
- No external-service-dependent tests were added; all gates use loopback/fake
  backends/temp dirs.