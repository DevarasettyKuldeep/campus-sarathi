# Phase 0: academic data investigation

Evidence checked on 2026-10-17. Public sources only; no login, student records,
credential collection, scraping or external mutations performed.

## Findings and limits

The [Coimbatore intranet AUMS description](https://intranet.cb.amrita.edu/aums)
describes course registration and attendance entry, e-learning assignments and
announcements, plus unique student logins. This establishes possible source
systems, not third-party permission or a usable API contract.

The [university AUMS page](https://www.amrita.edu/aums/) provides campus login
links and Coimbatore support contact `aumsadmin@amrita.edu`. It does not, in the
reviewed public material, establish a developer API or permission for Campus
Sārathi. Absence in these pages does not prove no API exists.

| Information | Candidate | Current integration decision | Manual path |
|---|---|---|---|
| Courses/subjects | AUMS academic module | Permission/API unknown | Student supplies code/name/semester |
| Timetable | Campus timetable/AUMS | Student-specific machine-readable feed unverified | Weekly sessions, location, semester bounds |
| Attendance | AUMS academic records | API/access agreement unverified | Student copies their own aggregate attended/conducted counts and observed time |
| Assignments | AUMS e-learning/LMS | LMS endpoint/token scope unverified | Title, subject/course, deadline and completion |
| Announcements | LMS/intranet | Reuse/access scope not verified | No official announcements populated; empty state until authorised source exists |
| Authentication | AUMS logins exist | They do not establish Google OAuth availability | Planned app Google identity restricted by brief; OAuth client registration required |

## Authorised data acquisition contract

Students can manually enter information they are entitled to use for their own
academic organisation, subject to notice/consent before collection in the
production app. Never label student-entered values as university verified.
Manual values retain source, entry time and observed update time. They remain
editable independently of future official snapshots. Unknown attendance policy
produces no official risk advice. No full portal access is needed for this path.

Before implementing any official adapter, obtain API documentation, written
authorisation/access scope, sandbox/sample contract, rate limits, authentication
method, retention/reuse terms and revocation/error behaviour. Verify source
freshness and reconcile identities without trusting client identifiers. Support
read-only retrieval first. Never store university passwords. No mock official
adapter is being shipped.

## Gate status

Public source investigation and manual acquisition design are documented.
Manual validation and durable local collection are implemented. Actual
file-backed SQLite close/reopen and UI/repository tests verify retained values,
provenance/timestamps, consent and local erasure. This proves the manual data
path in automated tests; Android device runtime verification remains pending
NDK repair and device availability. Official synchronisation is unavailable
pending institutional access, but is not mandatory for the manual-first path.
