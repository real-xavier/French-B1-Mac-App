# Builder configuration and ownership

The five distinct subordinate builder identities were explicitly created using model `gpt-6-luna`, reasoning effort `xhigh`, with no inherited conversation (`fork_turns: none`). At most three subordinate builders ran concurrently, alongside the execution owner. Follow-up work reused these identities and retained their model/settings.

1. `foundation`: shared Codable models, resource loading/search, clock/calendar-injected scheduler, atomic progress persistence, AppStore; then vocabulary batch02.
2. `vocabulary`: pinned FLELex import/provenance, editable authoring schema, coverage validators, licenses, vocabulary batch01.
3. `verbs`: deterministic Lefff morphology, auxiliary/reflexive composition and editorial overrides, materialized verb rows and original sentence frames.
4. `dictionary_ui`: Learn list/detail, native selectable NSTextView wrapper, tense picker/table; reserved for remaining authoring and interface fixes.
5. `review_testing`: Review flow, scheduler/store/content tests; then vocabulary batch04; later native app UI checks and real screenshots.

The execution owner froze `CONTRACT.md`, integrated and independently reviewed all code handoffs, authored vocabulary batch05, and owns app packaging and delivery. The parent coordinator independently monitors/reviews artifacts.
