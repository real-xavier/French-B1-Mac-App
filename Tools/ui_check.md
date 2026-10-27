# Native UI smoke check

Run this only against the packaged app after the complete vocabulary and verb corpus has been bundled. Capture real app windows with CUA; do not create synthetic screenshots.

Save three screenshots to `/Users/xavier/Codex/2026-10-27/realtime-voice-chat/outputs/Screenshots/`:

- `dictionary.png`: Learn selected, a useful entry open, with its article, English/French definitions, and examples visible.
- `verb.png`: a verb entry open with a conjugation table visible.
- `review.png`: Review selected with **All learned**, showing the French prompt and **Show answer** before revealing it.

Then verify the interactions in [TESTING.md](../Documentation/TESTING.md): add a card, reveal it, grade it, check the due and all-learned queues, exercise the Learn empty-state action, and try native text selection and the standard text menu. Confirm that the revealed face exposes grading controls and the prompt face does not. Use a disposable app-data location or avoid grading if changing the user's existing review progress would be undesirable.
