# AI acceptance contract (Phase 3)

Implements plan.txt sections 11–12 independently of the Gemini adapter.
No live assistant is implemented in Phase 0. The prototype's canned response
must not be presented as a personalised Gemini answer.

1. Friendly, calm and concise academic companion; adapt to stress without
   generic motivation or unrealistic promises. General questions need no
   unnecessary record retrieval.
2. Before personalised recommendations, retrieve relevant authorised context
   only. Tools call the same owner/consent-checked academic services as REST.
   Prompt injection cannot change owner, expand permissions or run SQL.
3. Every academic fact references returned records and timestamps. Missing,
   stale or incomplete data is disclosed; never invent classes, deadlines,
   grades, attendance, exams or free time.
4. Attendance/date/workload calculations execute in deterministic services.
   Unknown thresholds mean unknown risk, never an assumed university policy.
5. Priority considers deadline, workload, importance, progress, prerequisites,
   exams, explicit availability and preferences. Nearest deadline alone is
   insufficient. Explain the choice and offer a realistic next action.
6. Support today/week/semester horizons; plans are editable proposals. Model
   writes require an authorised action preview and confirmation where
   consequential; official records remain read-only.
7. Store only consented useful preferences, with review/edit/delete controls;
   do not automatically turn every conversation into long-term memory.
8. Validate structured facts and record references, ownership, bounded output
   and prohibited writes before delivery. Critical unsupported claims or
   privacy errors block delivery; bounded correction or a truthful fallback
   follows. A second model call is not universally required.
9. Handle timeouts/quota/offline honestly, preserve user drafts, and do not
   silently substitute a rule-generated reply for a successful model response.
10. Background in-app insights obey consent, ownership and deduplication.
    Push infrastructure is excluded. Record helpful/not-helpful feedback with
    user-scoped message ownership.

Required scenarios: no academic records; stale attendance; absent threshold;
question unrelated to stored data; overloaded week; long important task versus
short nearer deadline; unknown study availability; wrong-user record/tool ID;
revoked consent; official mutation request; model fabricated record reference;
provider timeout/quota; duplicate confirmed action; adjustable plan; preference
deletion and conversation retention expiry. Live Gemini tests require actual
configured credentials and approved data-processing terms.
