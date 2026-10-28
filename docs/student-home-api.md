# Student home and announcement integration

The frontend uses separate authenticated GET requests to `/students/home`,
`/announcements`, and `/upcoming_events`. It no longer reads embedded
`announcementsData` from the home response.

## Backend authorization

Allow STUDENT as well as HOSTEL_ADMIN on GET `/announcements`, as agreed.
POST `/announcements`, GET `/announcements/:id`, and PATCH `/announcements/:id`
remain admin-only. Student detail reads the authorized list payload and does
not call the admin-only detail endpoint. No delete endpoint is used.
The backend must enforce hostel scoping and student visibility as well as roles.

## Announcement response envelopes

Lists accept `{status: "success", data: [...], meta: {page, pageSize, totalPages}}`
or `{status: "success", data: {announcements: [...], totalAnnouncementsCount}, meta: ...}`.
Admin detail accepts `data: {...announcement}` or `data: {announcement: {...}}`.
The controller response was not supplied, so confirm these envelopes against
actual backend responses before release.

Students request ACTIVE announcements, fetch every page, and display only
announcements whose inclusive start/end calendar dates contain today's date
in Asia/Kolkata. Important notices come first, then newest notices.

Create sends all required schema fields. Edit patches changed fields only.
Dates use YYYY-MM-DD, without timezone conversion. An empty optional link is
omitted on create. Existing links can be replaced; the supplied schema cannot
clear them because it accepts neither null nor an empty URL. Push notification
is sent as a backend setting; this change does not add mobile push registration.

## Optional home fields

The existing confirmed frontend contract contains only `canMarkAttendance`.
A sample home response was requested. Until it is available, the frontend
supports the following optional shape and avoids invented profile/timing data:

```json
{
  "status": "success",
  "data": {
    "canMarkAttendance": true,
    "student": {
      "studentName": "Arun Kumar",
      "room": {"roomNumber": "NH-3-118"},
      "hostel": {"hostelName": "Our Hostel"},
      "hasProfilePhoto": true
    },
    "isMarkedToday": false,
    "markedAt": null,
    "attendanceWindow": {
      "opensAt": "2026-10-26T20:30:00+05:30",
      "closesAt": "2026-10-26T22:00:00+05:30"
    }
  }
}
```

Student fields can also be at the root of `data`; roomNumber and hostelName
can be flattened. `studentImageKey`/`studentImageUrl`, when explicitly present,
also indicate profile photo availability. `windowOpensAt`/`windowClosesAt`
are accepted instead of the nested window. Instants must include an offset
or Z; display times use Asia/Kolkata.

Card precedence is marked today, photo required, before opening, closed,
open and eligible, then unavailable. Without a marked flag or window times,
`canMarkAttendance: false` shows a neutral unavailable state rather than
claiming the student missed attendance. A successful submission is remembered
locally for that hostel calendar day; server fields preserve it across restarts.
The frontend refreshes home data at window boundaries, at hostel midnight,
on app resume, and on pull-to-refresh.

Student navigation includes Home, Leave, Notices, and Events. Fees are not
implemented because no fee API or existing fee flow was supplied.
