# OMA — unified hackathon integration (selective merge)

Source branch: `feature/oma-vibe-mode` at `d970e593ea6f`. Unified edition integrates the essential work from all active branches without deleting or rewriting the originals.

## Included

- Original Golden Flow + AntiFail, ZeroBuy, Domino and Proof — already in the VIBE branch through main/brand history.
- Original HOME TWIN + brand UI + VIBE opt-in SwiftUI and responsive PWA — already in the VIBE branch.
- Photo-based HOME TWIN from `feature/oma-finance-banking`: seven rooms / 58.67 m², local photorealistic synthetic renders, progress and old-data migration. This replaces the heavier 80 m² SceneKit visual approach, **without adding banking**.
- Offline help-with-master request from `feature/oma-quality-service-flow`: explicit local-only request, validation, cancellation, model tests and iOS entry in task flow.
- Pilot unit economics and release checklist from the quality branch.

## Intentionally excluded

- Finance banking simulation, transfer-like UI, synthetic balances, backend financial endpoints and DB migration: no approved bank / contract; scope would distract from OMA VIBE and create additional risk. Original branch is preserved.
- Duplicated CI workflow from quality branch: current `.github/workflows/oma-quality.yml` is the unified quality gate. It should run service and HOME TWIN tests under `npm test`.
- Arbitrary "AI room scan", verified contractor booking or actual product checkout: not implemented or externally approved.

## Product boundaries

Classic and VIBE share demo products and basket, not live stock or payments. Browser VIBE drafts are local to that browser while iOS VIBE drafts share native Store. Bedroom inspiration is synthetic and not a live photo transformation. Current demo catalog is too small to fully outfit the bedroom: footwear and hallway storage suggestions are **not a completed bedroom kit**; do not claim otherwise. HOME TWIN room dimensions are not measured construction data. Request to a master is only stored on-device, never transmitted.

## Verification before merging into main

1. Check `npm ci && npm run typecheck && npm run test:proof && npm test && npm run test:e2e && npm run check:ios-evidence`.
2. Compile in Xcode Simulator; the GitHub Actions job only proves compilation, not physical-device performance.
3. Manually test Classic → VIBE → Classic, shared cart, offline cache, HOME TWIN saved progress/data migration, and service request persistence/cancellation.
4. Do not merge to main or deploy until current-head CI is green and the demo flow is rehearsed end to end.
