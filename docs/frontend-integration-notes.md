# Frontend integration update

Implemented against the backend's `docs/frontend-updates-guide.md`, dated 25 October 2026.

## Implemented

- Admin header loads `/hostel_admin/splash_screen`, retaining the profile ID in provider state and displaying admin, hostel, and college names. Missing profiles display an unavailable state.
- Students, rooms, leave applications, attendance, and events explicitly request `page=1&pageSize=20` initially and read pagination from top-level `meta`.
- Listing filters use each endpoint's documented query keys. Text searches debounce, changed filters reset pagination, and stale list responses are cancelled or ignored.
- Student department/room labels come from lookup data. Room lookup traverses every page.
- Room cards display capacity, occupancy, remaining beds, vacancy status, editing, and a separately fetched occupants panel.
- Leave status totals use `statusesCount`, independent of the selected status and visible page. Details show business review time and hide audit timestamps.
- Present attendance displays the attendance day and reported time in IST, profile and capture photos, department/room, face percentage, radius/distance, maps, and student/parent contact actions.
- Absent attendance uses flat student fields, roll-number row keys, missed-date counts, and expandable dates.
- Percentage filtering is present-only; the absence summary is hidden while it is active. Student-filtered totals are labelled matching students.
- Student details include editable roll, phone, and parent mobile fields. Updates contain only changed fields, display field validation errors, and refetch the saved profile. Ignored roll-number updates are reported explicitly.
- Calendar dates preserve the returned date portion. Leave range updates send both dates together.
- Event picker values are interpreted in `Asia/Kolkata`; event payloads use UTC timestamps with exactly three fractional digits. Event displays use the same named zone independently of device timezone.
- Signed media URLs are shared by object key and refreshed after four minutes while observed. Null student images use a profile placeholder. Missing optional event images/links are hidden.

## Backend dependencies retained

- Roll-number persistence still requires the backend service/repository fix. The frontend checks the returned value instead of reporting an unconfirmed save.
- Outside-hostel filtering remains unavailable because query validation and service names/boolean parsing disagree.
- Events explicitly send `is_active=false` for all events or `true` for active events. There is no server-side inactive-only mode.
- Event pages are sliced locally from the complete response; navigating pages does not repeatedly request and append the same events.
- Event date controls describe containment with UTC boundaries, rather than exact IST-day overlap.
- A null leave review timestamp remains unavailable; audit timestamps are not substituted for it.

## Validation

The Flutter test suite covers request/response contracts, IST conversion, exact timestamp precision, calendar dates, room lookup pagination, pagination reset, event client pagination, student-save confirmation, and existing navigation/authentication behavior.

No live backend, deployed database migration, physical-device camera, phone dialer, or maps integration was exercised. The guide's mess-bill date example is a contract reference; this project has no mess-billing feature to update.
