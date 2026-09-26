# Hostel Management System — Feature & Implementation Specification

## 1. Purpose

This document is the implementation specification for the **Hostel Management System**.

It is intended to be used by a coding agent as the source of truth for implementing the application. The agent should preserve the existing architecture and completed functionality and implement features incrementally without breaking existing modules.

---

# 2. Project Scope

The system manages hostel operations for colleges/institutions.

The main users currently considered are:

- **Student**
- **Hostel Admin**

The system must support strict tenant/hostel isolation.

### Important authorization rule

A `HOSTEL_ADMIN` manages **exactly one hostel**.

The admin's hostel scope must be derived from the authenticated user:

```text
req.user
   ↓
HostelAdminProfile
   ↓
hostelId
```

An admin must never be able to access or modify students, rooms, allocations, attendance, leave requests, etc. belonging to another hostel.

Multi-college/tenant isolation is a hard requirement.

---

# 3. Current Backend Status

The backend already has the following major areas completed or established:

1. Database design and seeding
2. Authentication
3. Authorization / RBAC
4. Student create/update/status/list/detail
5. Hostel data/seeding
6. Leave request module
7. Special permission module
8. Attendance module

The project uses:

- Node.js backend
- PostgreSQL
- Prisma ORM
- Prisma migrations
- REST-style APIs
- Authentication + authorization middleware
- Service/controller/repository style separation where applicable

Do not rewrite completed modules unnecessarily.

---

# 4. Core Roles

## 4.1 Student

A student should be able to access only data/actions allowed for the authenticated student.

Expected capabilities include:

- View own profile
- View own hostel/room information
- Submit leave requests
- View leave request status/history
- Submit/request special permission
- View special permission status/history
- View attendance information relevant to the student

Students must not access another student's private records.

---

## 4.2 Hostel Admin

A hostel admin manages one hostel.

Expected capabilities include:

- Manage hostel information within the allowed scope
- Manage rooms
- Manage students belonging to the hostel
- Allocate/deallocate students to rooms
- Manage leave requests
- Approve/reject leave requests
- Manage special permissions
- View/manage attendance
- View hostel operational information

Every admin operation must be authorized against the admin's hostel scope.

---

# 5. Authentication

Authentication is already implemented.

There is a **single login flow/API** capable of identifying the user and determining whether the user is a student or hostel admin.

Authentication responsibilities:

- Validate credentials
- Authenticate the user
- Establish authenticated identity
- Provide role information
- Provide enough identity information for authorization

Authorization must never rely only on client-provided `hostelId`.

---

# 6. Authorization / RBAC

Authorization is already implemented and must remain consistent throughout all modules.

Use role-based permissions such as:

```text
STUDENT
HOSTEL_ADMIN
```

The backend must enforce authorization server-side.

Never trust:

```text
hostelId
studentId
roomId
adminId
```

from the frontend without validating ownership/scope.

### Example

If Admin A belongs to Hostel 1:

```text
Admin A → Hostel 1
```

Admin A must not be able to:

```text
GET student from Hostel 2
PATCH student from Hostel 2
GET room from Hostel 2
allocate student from Hostel 2
approve leave request from Hostel 2
view attendance from Hostel 2
```

even if the IDs are manually supplied in the request.

---

# 7. Hostel Management

Hostels are seeded/managed as core system data.

### Existing decision

Hostel records are primarily seeded and are not intended to have unrestricted CRUD from hostel admins.

The accepted admin operation is:

```text
PATCH hostel
```

A hostel admin may edit permitted hostel information for their own hostel.

### Requirements

- Admin can update only their own hostel.
- Validate all editable fields.
- Never allow changing the hostel's identity/scope in a way that breaks authorization.
- Prevent an admin from assigning themselves to another hostel through an API request.

---

# 8. Student Management

Student management is already implemented.

Expected functionality:

### Create student

Admin can create a student belonging to the admin's hostel.

### Update student

Admin can update permitted student information.

### Student status

Student status must be manageable, for example:

```text
ACTIVE
INACTIVE
```

(or the exact enum/status values already established in the existing schema).

### Student list

Admin can retrieve students belonging to their hostel.

Support useful filtering/pagination where already established.

### Student detail

Admin can retrieve the details of a student only when that student belongs to the admin's hostel.

### Isolation

A student from another hostel must return an authorization/not-found style response according to the existing project conventions.

---

# 9. Room Management

Room management is a core module.

## Required functionality

### Room CRUD

Hostel admins should be able to:

- Create room
- View rooms
- View room details
- Update room
- Delete/deactivate room where appropriate

### Room data

The exact schema should follow the existing Prisma model, but typically includes:

- Room number/name
- Hostel
- Capacity
- Current occupancy
- Status

Do not duplicate occupancy data if the existing schema derives it through allocations.

### Important constraints

- Room belongs to exactly one hostel.
- Admin can access only rooms in their hostel.
- Room number should follow appropriate uniqueness rules within a hostel.
- A room must not exceed capacity.
- A room belonging to another hostel must never be accessible through another admin.

---

# 10. Student ↔ Room Allocation

The system must support assigning students to hostel rooms.

## Required operations

- Allocate student to room
- View student's current allocation
- View room occupants
- Change room allocation
- Deallocate student when applicable

## Business rules

### Hostel isolation

Student and room must belong to the same hostel.

```text
student.hostelId === room.hostelId
```

must be enforced server-side.

### Capacity

A room must not exceed its configured capacity.

### Duplicate active allocation

A student should not have multiple simultaneous active room allocations.

### Reallocation

When moving a student:

```text
Old allocation → ended/deactivated
New allocation → created/activated
```

Maintain historical allocation data if the existing model supports allocation history.

---

# 11. Leave Management

Leave requests are a separate domain/module.

The established workflow is:

```text
Student creates leave request
        ↓
Hostel Admin views request
        ↓
Admin approves OR rejects
        ↓
Student can see final status
```

## Student functionality

- Create leave request
- View own leave requests
- View request status
- View leave history

## Admin functionality

- List leave requests for their hostel
- View leave request details
- Approve leave
- Reject leave

## Leave lifecycle

Use the status model already defined in the database.

Conceptually:

```text
PENDING
   ├── APPROVED
   └── REJECTED
```

### Important rules

- Student can create a request only for themselves.
- Student cannot approve/reject their own request.
- Admin can act only on requests belonging to students in their hostel.
- Invalid state transitions must be rejected.
- Validate leave dates.
- Preserve request history/status.

---

# 12. Special Permission

Special permission is another separate module/domain.

It should follow a workflow similar to leave but represent permission requests for special circumstances.

## Student

- Create/request special permission
- View own requests
- View status/history

## Hostel Admin

- View requests belonging to their hostel
- Approve request
- Reject request

## Security

- Student can act only on their own requests.
- Admin can act only on requests inside their hostel.
- Never trust a client-provided hostel ID for authorization.
- Validate status transitions.

---

# 13. Attendance

Attendance is an important completed backend module.

Attendance records are associated with students and are intended to support hostel attendance monitoring.

The attendance UI/table requirements discussed for the frontend include:

| Field | Purpose |
|---|---|
| Student name | Identify student |
| Roll number | Student identifier |
| Room number | Current hostel room |
| Captured image | Image captured during attendance |
| Face matching percentage | Face-recognition confidence/similarity result |
| Location deviation from hostel | Distance/deviation from expected hostel location |
| Location coordinates link | Open attendance coordinates on a map |
| Attendance status | Present/absent as applicable |

---

# 14. Attendance + Face Recognition

The attendance system uses face recognition.

Conceptually:

```text
Captured face image
       ↓
Face recognition model
       ↓
Face embedding/vector
       ↓
Compare with registered student face embedding
       ↓
Similarity score
       ↓
Attendance decision
```

A face image is represented by an embedding vector (the project discussion used a 512-dimensional representation).

The comparison produces a similarity score, commonly using cosine similarity.

The backend should preserve the actual score/percentage required by the existing attendance schema/API.

Do not expose raw model internals to the frontend unless explicitly required.

---

# 15. Attendance + Location Verification

Attendance also considers the captured location.

The system should retain the attendance coordinates and calculate/record deviation from the hostel's expected location.

Frontend should be able to show:

```text
Location deviation from hostel
```

and a clickable:

```text
Location coordinates → map
```

The backend must validate location-related data according to the existing attendance rules.

Do not trust a client-provided "valid location" boolean without independently applying the project's validation logic.

---

# 16. Attendance Query Requirements

The attendance API should support viewing records for:

### Single date

Example:

```text
attendance?date=YYYY-MM-DD
```

### Date range

Example:

```text
attendance?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD
```

The exact query parameter names should follow the existing implementation.

### Present and absent students

The frontend needs a complete attendance view.

For a selected date/date range:

- Students with attendance records should appear as present/recorded.
- Students who have no applicable attendance record should be identifiable as absent according to the established attendance rules.

For date ranges, absence logic must follow the project's intended semantics rather than simply assuming that one missing record means permanently absent.

---

# 17. Attendance API Response Design

The frontend should receive enough information to render the attendance table without making unnecessary N+1 requests.

The response should be able to provide, as applicable:

```text
student_name
roll_number
room_number
captured_image
face_matching_percentage
location_deviation_from_hostel
location_coordinates
attendance_status
date/time
```

Prefer a backend response designed for the UI rather than forcing the frontend to reconstruct relationships manually.

---

# 18. Frontend

The frontend is being started after the backend attendance feature.

The frontend stack discussed for this project is:

- React
- Vite
- Tailwind CSS
- React Router

The application should have:

```text
Public Routes
Private Routes
```

Private routes must require authentication.

Role-specific pages/components should be protected based on authorization.

---

# 19. Frontend Routing

Conceptually:

```text
Public
├── Login
└── Other public pages

Private
├── Dashboard
├── Students
├── Rooms
├── Allocations
├── Leave
├── Special Permission
├── Attendance
└── Other authorized modules
```

The exact routes should match the frontend implementation.

Authentication state should be centralized rather than duplicated across every page.

---

# 20. Frontend UI Expectations

Use reusable components for:

- Tables
- Forms
- Modals/dialogs
- Buttons
- Inputs
- Selects
- Status badges
- Loading states
- Error states
- Empty states
- Pagination/filter controls

Tailwind should use the project's configured design tokens/classes, including project-level primary/secondary colors where already configured.

Avoid duplicating large blocks of styling or API logic across pages.

---

# 21. Backend API Architecture

Follow the existing backend architecture.

A typical feature should remain separated into:

```text
route
  ↓
middleware
  ↓
controller
  ↓
service
  ↓
repository/data access
  ↓
Prisma
  ↓
PostgreSQL
```

Validation should happen at the API boundary.

Business rules should live in the service/domain layer rather than only in controllers.

Authorization must be enforced before sensitive operations.

---

# 22. Database

The project uses:

```text
PostgreSQL
Prisma ORM
Prisma migrations
```

Use Prisma migrations for schema changes.

Never manually modify production database structure without corresponding Prisma migration changes.

When changing relationships:

1. Update Prisma schema.
2. Generate migration.
3. Test migration.
4. Run existing tests.
5. Verify existing modules are not broken.

---

# 23. Data Relationship Principles

The core relationship model is conceptually:

```text
College / Tenant
       │
       └── Hostel
             │
             ├── HostelAdminProfile
             │
             ├── Rooms
             │      │
             │      └── Allocations
             │                │
             │                └── Student
             │
             ├── Students
             │      │
             │      ├── Leave Requests
             │      ├── Special Permissions
             │      └── Attendance
             │
             └── Hostel configuration
```

The exact schema and existing model names are authoritative over this conceptual diagram.

---

# 24. Validation

Every module must validate:

- Required fields
- Data types
- Date formats
- Date relationships
- Enum/status values
- IDs
- Ownership/scope
- Capacity constraints
- Duplicate operations
- State transitions

Never rely only on frontend validation.

Backend validation is mandatory.

---

# 25. Error Handling

Use consistent API errors.

Errors should clearly distinguish, where the existing project convention permits:

```text
400 → Invalid request/data
401 → Unauthenticated
403 → Authenticated but unauthorized
404 → Resource not found
409 → Conflict/business-rule violation
500 → Unexpected server error
```

Do not leak sensitive implementation/database information in production errors.

---

# 26. Security Rules

These are non-negotiable.

### Never trust client ownership fields

For example, do not authorize using:

```json
{
  "hostelId": "..."
}
```

alone.

Instead derive the authenticated user's scope from the database.

### Prevent IDOR

A user must not access another user's resources simply by changing an ID in the URL.

Examples:

```text
/students/123
/students/124
```

must still be authorization-checked.

### Admin hostel scope

Always derive:

```text
admin → HostelAdminProfile → hostelId
```

and apply that scope to database queries.

---

# 27. Testing

Every new backend feature should include tests for:

## Happy paths

- Valid create
- Valid read
- Valid update
- Valid delete/action
- Valid status transition

## Authorization

- Student cannot perform admin operation.
- Admin cannot access another hostel.
- Student cannot access another student's private request.
- Cross-hostel student/room allocation is rejected.

## Validation

- Missing required fields
- Invalid IDs
- Invalid dates
- Invalid statuses
- Duplicate operations
- Capacity violations

## Edge cases

Test boundary conditions rather than only normal cases.

---

# 28. Planned / Future Modules

The original roadmap included the following modules after the core hostel operations:

1. Announcements
2. Food / Menu
3. Events
4. Mess Fees / Payments
5. Parent Notifications
6. Absentee Reports
7. Excel Export
8. Dashboard

Additional modules that were explicitly considered for later:

- Complaints
- Visitors

These should not be allowed to destabilize the already completed core modules.

---

# 29. Suggested Implementation Order

The established progression is:

```text
Database / Seeding
        ↓
Authentication
        ↓
Authorization / RBAC
        ↓
Student Management
        ↓
Hostel Management
        ↓
Room Management
        ↓
Student ↔ Room Allocation
        ↓
Leave
        ↓
Special Permission
        ↓
Attendance
        ↓
Announcements
        ↓
Food / Menu
        ↓
Events
        ↓
Mess Fees / Payments
        ↓
Parent Notifications
        ↓
Absentee Reports
        ↓
Excel Export
        ↓
Dashboard
```

Complaints and visitors can be added later.

---

# 30. Immediate Development Context

The backend has progressed through **attendance**.

The current development focus is moving toward the **frontend**.

The frontend should consume the existing backend APIs rather than recreating business logic.

A team member may also implement one simple backend module independently. A suitable simple module from the roadmap can be selected without interfering with the core attendance/frontend work.

---

# 31. Email / Notifications

Email sending was discussed as a future infrastructure requirement.

The project should use a proper transactional email solution rather than putting email delivery logic directly into business controllers.

Potential use cases include:

- Leave status notifications
- Special permission status notifications
- Parent notifications
- Important hostel announcements
- Other transactional notifications

The implementation should keep email delivery behind a service/interface so the provider can be changed without rewriting business logic.

---

# 32. Deployment Context

The backend has been deployed/tested using an AWS EC2 instance.

The project has also involved:

- Linux/Ubuntu server administration
- PostgreSQL
- Prisma migrations
- Docker/CI/CD exploration
- Bitbucket pipeline/runner work

Deployment-specific configuration must not be hard-coded into application logic.

Use environment variables for:

```text
DATABASE_URL
JWT/auth secrets
email provider credentials
AWS credentials/configuration
other external service secrets
```

Never commit secrets to Git.

---

# 33. Coding-Agent Instructions

When implementing a task from this document:

### Step 1 — Inspect existing code

Before writing code:

- Inspect the Prisma schema.
- Inspect existing routes.
- Inspect controllers.
- Inspect services.
- Inspect repositories/data-access code.
- Inspect middleware.
- Inspect validation.
- Inspect tests.
- Inspect frontend API/client structure.

Do not assume model or file names from this document if the repository already has established names.

### Step 2 — Reuse existing patterns

Follow the project's existing:

- Naming conventions
- Folder structure
- Error handling
- Validation library/pattern
- Authentication middleware
- Authorization middleware
- Response format
- Prisma patterns
- Testing conventions

Do not introduce a second architecture for the same problem.

### Step 3 — Preserve existing behavior

Before modifying shared code, identify all existing consumers.

Do not break:

- Authentication
- Authorization
- Student management
- Hostel scope isolation
- Leave
- Special permission
- Attendance

### Step 4 — Implement incrementally

For each feature:

```text
Schema (only if necessary)
        ↓
Migration
        ↓
Validation
        ↓
Repository/data access
        ↓
Service/business logic
        ↓
Controller
        ↓
Routes
        ↓
Authorization
        ↓
Tests
        ↓
Frontend integration
```

### Step 5 — Verify

After implementation:

- Run tests.
- Run lint/type checks if configured.
- Run Prisma validation/generation where relevant.
- Verify migrations.
- Test unauthorized/cross-hostel access.
- Test the frontend against the real API contract.

---

# 34. Definition of Done

A feature is complete only when:

- [ ] Database changes are implemented correctly if required.
- [ ] Prisma migration exists if schema changed.
- [ ] API endpoint exists.
- [ ] Authentication requirement is correct.
- [ ] Authorization is correct.
- [ ] Hostel scope is enforced.
- [ ] Input validation exists.
- [ ] Business rules are enforced server-side.
- [ ] Error handling is consistent.
- [ ] Tests cover happy paths.
- [ ] Tests cover authorization.
- [ ] Tests cover important edge cases.
- [ ] Frontend integration is complete when applicable.
- [ ] Loading/error/empty states are handled in UI.
- [ ] Existing functionality still works.
- [ ] No secrets are committed.
- [ ] Documentation is updated when API behavior changes.

---

# 35. Critical Invariants

The coding agent must treat these as hard invariants:

1. **A hostel admin manages exactly one hostel.**
2. **Admin hostel scope comes from authenticated identity, not arbitrary request data.**
3. **Cross-hostel access is forbidden.**
4. **Students cannot access or modify another student's private resources.**
5. **Students cannot perform hostel-admin operations.**
6. **Room capacity cannot be exceeded.**
7. **A student cannot have multiple active room allocations.**
8. **Leave and special-permission status transitions must be valid.**
9. **Attendance data must preserve face-match and location information required by the UI.**
10. **Frontend validation never replaces backend validation.**
11. **Existing completed modules must not be broken while adding new features.**
12. **Database schema changes must use Prisma migrations.**
13. **Secrets must be supplied through environment configuration.**

---

# 36. High-Level System Goal

The final product should provide a secure, multi-hostel hostel-management platform where:

```text
Students
   │
   ├── Manage/view their own information
   ├── Request leave
   ├── Request special permission
   └── View attendance

Hostel Admin
   │
   ├── Manage hostel
   ├── Manage students
   ├── Manage rooms
   ├── Allocate students
   ├── Manage leave
   ├── Manage special permissions
   └── Monitor attendance

Future
   │
   ├── Announcements
   ├── Food/Menu
   ├── Events
   ├── Mess fees/payments
   ├── Parent notifications
   ├── Absentee reports
   ├── Excel export
   ├── Dashboard
   ├── Complaints
   └── Visitors
```

The coding agent should use the **existing repository implementation as the technical source of truth** and this document as the **product/feature specification**.
