# Database Design & Conceptual Schema

This document is a living artifact that tracks the conceptual schema and database design for the Polyglot Attendance & Seniority Tracker.
It will be continuously updated as the database schema evolves.

**Source of Truth:** [schema-postgres.sql](./schema-postgres.sql)

---

## 1. PostgreSQL — Relational Foundation

PostgreSQL is the single source of truth for identity, roles, permissions, and the organizational (SG) hierarchy. Every table uses `UUID` as its primary key.

---

### 1.1. Domain Groups

The tables are logically grouped into **four domains**:

| Domain | Tables | Purpose |
| :--- | :--- | :--- |
| **Identity & Access** | `users`, `roles`, `permissions`, `role_permission_mapper` | Who the user is, what role they hold, and what they can do. |
| **SG Hierarchy** | `sg_zones`, `sg_states`, `sg_areas`, `sg_centers`, `sg_endpoints` | The organizational tree from Zone down to Endpoint. |
| **Sewa Catalog** | `sewa_catalog` | Master list of sewa (service) categories. |
| **User Details** | `sewadar_details`, `moderator_details` | Role-specific profile extensions for sewadars and moderators. |

---

### 1.2. Table Definitions

#### `users`
The core identity table. Every user in the system has exactly one record here.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `id` | UUID | **PK** | Universal anchor across all databases. |
| `firstname` | VARCHAR(255) | NOT NULL | |
| `lastname` | VARCHAR(255) | NOT NULL | |
| `phone_number` | VARCHAR(255) | NOT NULL | |
| `email` | VARCHAR(255) | NOT NULL | |
| `aadhar_number` | BIGINT | NOT NULL | |
| `profile_pic` | VARCHAR(255) | NOT NULL | URL/path to profile image. |
| `role` | VARCHAR(255) | NOT NULL, **FK -> roles.role_name** | Textual role, not a UUID join. |
| `adr_house` | VARCHAR(255) | NOT NULL | Address line — house/building. |
| `adr_area` | VARCHAR(255) | NOT NULL | Address line — area/locality. |
| `adr_city` | VARCHAR(255) | NOT NULL | |
| `adr_state` | VARCHAR(255) | NOT NULL | |
| `adr_pincode` | VARCHAR(255) | NOT NULL | |
| `is_approved` | BOOLEAN | NOT NULL | Whether the user account is approved. |
| `sg_endpoint_id` | UUID | NOT NULL, **FK -> sg_endpoints.id** | The SG endpoint this user belongs to. |

---

#### `roles`
Master list of roles available in the system.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `id` | UUID | **PK** | |
| `role_name` | VARCHAR(255) | NOT NULL, **UNIQUE** | Unique constraint required since `users.role` references this column. |
| `desc` | TEXT | NOT NULL | Description of the role. |

---

#### `permissions`
Master list of granular permissions.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `id` | UUID | **PK** | |
| `permission_tag` | VARCHAR(255) | NOT NULL | Machine-readable tag (e.g., `CAN_VIEW_REPORTS`). |
| `desc` | TEXT | NOT NULL | Human-readable description. |

---

#### `role_permission_mapper`
Many-to-many join table linking roles to permissions.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `role_id` | UUID | **Composite PK**, **FK -> roles.id** | |
| `permission_id` | UUID | **Composite PK**, **FK -> permissions.id** | |

---

#### `sg_zones`
Top level of the SG hierarchy.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `id` | UUID | **PK** | |
| `name` | VARCHAR(255) | NOT NULL | |
| `code` | VARCHAR(255) | NOT NULL | Short code identifier. |

---

#### `sg_states`
Second level of the SG hierarchy. Each state belongs to one zone.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `id` | UUID | **PK** | |
| `name` | VARCHAR(255) | NOT NULL | |
| `code` | VARCHAR(255) | NOT NULL | |
| `zone_id` | UUID | NOT NULL, **FK -> sg_zones.id** | |

---

#### `sg_areas`
Third level. Each area belongs to one state.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `id` | UUID | **PK** | |
| `name` | VARCHAR(255) | NOT NULL | |
| `code` | VARCHAR(255) | NOT NULL | |
| `state_id` | UUID | NOT NULL, **FK -> sg_states.id** | |

---

#### `sg_centers`
Fourth level. Each center belongs to one area. Centers have geographic coordinates.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `id` | UUID | **PK** | |
| `name` | VARCHAR(255) | NOT NULL | |
| `code` | VARCHAR(255) | NOT NULL | |
| `n_cord` | VARCHAR(255) | NOT NULL | North (latitude) coordinate. |
| `e_cord` | VARCHAR(255) | NOT NULL | East (longitude) coordinate. |
| `address` | TEXT | NOT NULL | Full address text. |
| `area_id` | UUID | NOT NULL, **FK -> sg_areas.id** | |

---

#### `sg_endpoints`
Fifth and lowest level. Each endpoint belongs to one center. Endpoints also have coordinates.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `id` | UUID | **PK** | |
| `type` | VARCHAR(255) | NOT NULL | Type of endpoint. |
| `name` | VARCHAR(255) | NOT NULL | |
| `code` | VARCHAR(255) | NOT NULL | |
| `n_cord` | VARCHAR(255) | NOT NULL | North (latitude) coordinate. |
| `e_cord` | VARCHAR(255) | NOT NULL | East (longitude) coordinate. |
| `address` | TEXT | NOT NULL | Full address text. |
| `center_id` | UUID | NOT NULL, **FK -> sg_centers.id** | |

---

#### `sewa_catalog`
Master catalog of sewa (service) types.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `id` | UUID | **PK** | |
| `tag` | VARCHAR(255) | NOT NULL | Machine-readable tag. |
| `name` | VARCHAR(255) | NOT NULL | Human-readable name. |

---

#### `sewadar_details`
Extension table for users who are sewadars. 1:1 relationship with `users`.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `user_id` | UUID | **PK**, **FK -> users.id** | 1:1 link to the users table. |
| `batch_id` | VARCHAR(255) | NOT NULL | |
| `category_id` | UUID | NOT NULL, **FK -> sewa_catalog.id** | |
| `apply_date` | TIMESTAMPTZ(0) | NOT NULL | Date the sewadar applied. |
| `join_date` | TIMESTAMPTZ(0) | NOT NULL | Date the sewadar officially joined. |

---

#### `moderator_details`
Extension table for users who are moderators. 1:1 relationship with `users`.

| Column | Type | Constraints | Notes |
| :--- | :--- | :--- | :--- |
| `user_id` | UUID | **PK**, **FK -> users.id** | 1:1 link to the users table. |
| `mod_id` | UUID | NOT NULL | Unique moderator identifier. |
| `category_id` | UUID | NOT NULL, **FK -> sewa_catalog.id** | |
| `apply_date` | TIMESTAMPTZ(0) | NOT NULL | Date the moderator applied. |
| `join_date` | TIMESTAMPTZ(0) | NOT NULL | Date the moderator officially joined. |

---

### 1.3. Relationship Map

```text
SG Hierarchy (5-level tree):

  sg_zones
    └── sg_states        (zone_id FK)
         └── sg_areas    (state_id FK)
              └── sg_centers   (area_id FK)
                   └── sg_endpoints  (center_id FK)

Identity & Access:

  roles ──(role_name UNIQUE)──< users.role (FK)
    │
    └──< role_permission_mapper >──┘
                                    permissions

User Detail Extensions (1:1 off users):

  users
    ├── sewadar_details   (user_id PK+FK)  ──> sewa_catalog (category_id FK)
    └── moderator_details (user_id PK+FK)  ──> sewa_catalog (category_id FK)

Cross-domain link:

  users.sg_endpoint_id ──FK──> sg_endpoints.id
```

---

## 2. MongoDB — Append-Only Log

*(Schema to be defined when attendance logging is implemented.)*

The `user_id` (UUID) field in every MongoDB document will map back to `users.id` in PostgreSQL. This join is enforced at the application layer, not by database constraints.

---

## 3. Redis — Live State & Message Broker

*(Key patterns to be defined when live state and queues are implemented.)*

Redis keys will use the pattern `user:status:{uuid}` mapping back to `users.id` in PostgreSQL.

---

## 4. Cross-Database Integrity Rules

1. **PostgreSQL is the Parent:** A UUID must exist in `users` (PostgreSQL) before it can be used as a `user_id` in any MongoDB document or Redis key.
2. **Cascading Deletes/Archiving:** If a user is removed from PostgreSQL, the application code must trigger an async background worker to clean up or archive that user's data in MongoDB and wipe their keys from Redis.
3. **The Universal Anchor:** `users.id` (UUID) is the single thread tying all three storage engines together.
