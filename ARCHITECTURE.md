# System Architecture Blueprint: Polyglot Attendance & Seniority Tracker

## 1. Executive Overview
This system is a distributed, polyglot microservices architecture designed to handle hierarchical employee management and high-frequency attendance logging. It utilizes Service Level Separation (SLS) and Polyglot Persistence to decouple lightweight I/O operations (orchestration and state) from heavy CPU-bound operations (geospatial validation and analytical processing).

## 2. Core Services (Service Level Separation)
The application layer is divided into two backend domains operating within a private network.

### 2.1. Orchestration Layer (NestJS / Node.js)
* **Role:** The Public Gateway and State Manager.
* **Primary Tasks:** Authentication, session validation, WebSocket management, and lightweight CRUD.
* **Database Access:** Direct ownership of the Users schema (PostgreSQL) and the Live State (Redis).
* **Rationale:** Node.js is optimized for asynchronous I/O and handling thousands of concurrent lightweight connections, making it the ideal entry point for API clients.

### 2.2. Intelligence Layer (FastAPI / Python)
* **Role:** The Logic and Processing Engine.
* **Primary Tasks:** Geofence math, complex seniority tree traversal, anomaly detection, and data aggregation.
* **Database Access:** Direct ownership of Attendance_Logs (MongoDB) and analytical read-access to the hierarchy (PostgreSQL).
* **Rationale:** Python’s ecosystem (Pandas, Shapely, NumPy) is superior for CPU-bound data processing and mathematical validation. It remains completely isolated from public internet traffic.

### 2.3. Frontend & BFF Layer (Next.js)
* **Role:** Client UI and Backend-For-Frontend (BFF) proxy.
* **Primary Tasks:** Server-Side Rendering (SSR), UI delivery, and acting as a secure bridge between the browser and the NestJS API.
* **Security Implementation:** The NestJS orchestration layer strictly issues JWTs. The Next.js server intercepts this JWT and issues a secure httpOnly cookie to the browser, protecting against XSS attacks while maintaining the "Pure API" integrity of the backend.
* **Communication:** Interacts with the NestJS API via REST/JSON.

## 3. Database Architecture (Polyglot Persistence)
The system utilizes three distinct storage engines, completely decoupled at the database level. Data relations are enforced at the application layer via a universal `user_id` (UUID).

### 3.1. PostgreSQL (The Relational Foundation)
* **Purpose:** The single source of truth for identity and structural hierarchy.
* **Core Tables:**
  * `Users`: id (UUID PK), credentials, profile_data.
  * `Organization`: user_id (FK), manager_id (FK), seniority_level.
* **Execution Strategy:** Uses Recursive Common Table Expressions (CTEs) or the `ltree` extension to fetch deep organizational trees in a single, highly optimized query.

### 3.2. MongoDB (The Append-Only Log)
* **Purpose:** High-velocity write storage for attendance events.
* **Core Collections:**
  * `Attendance_Logs`: user_id (UUID), timestamp, coordinates (GeoJSON), action (IN/OUT), status.
* **Execution Strategy:** Treated as an immutable time-series ledger. Updates are rarely performed; data is only inserted. Fast write speeds prevent database locking during high-traffic shift changes.

### 3.3. Redis (The Live State & Message Broker)
* **Purpose:** In-memory caching and inter-service messaging.
* **Core Implementations:**
  * `Live Status`: Key-value pairs (`user:status:{uuid}` -> "online") with Time-To-Live (TTL) expiration.
  * `Pub/Sub & Queues`: Uses Redis Streams or BullMQ to pass asynchronous background jobs from NestJS to Python.

## 4. Communication Protocols
To maintain performance, the system uses distinct communication protocols based on the network boundary and urgency.

| Boundary | Protocol | Format | Rationale |
| :--- | :--- | :--- | :--- |
| **External** (Client -> NestJS) | HTTP/REST | JSON | Universal compatibility (Next.js, iOS, Android). Human-readable for easier debugging. |
| **Internal Sync** (NestJS -> Python) | gRPC / HTTP2 | Protobuf / JSON | Ultra-low latency. Used when the client is waiting for a validation response (e.g., geofence check). |
| **Internal Async** (NestJS -> Queue) | Redis Streams | Binary / JSON | Fire-and-forget. Used for heavy processing (reports, notifications) where the user does not need to wait. |

## 5. Security & Authentication Model
The architecture strictly adheres to a "Pure API" philosophy, completely agnostic to the client interface.
* **Stateless Authentication:** No server-side sessions or cookies (at the API level).
* **Token Standard:** JWT (JSON Web Tokens) signed via RS256 or HS256.
* **Token Flow:**
  1. Client authenticates via NestJS.
  2. NestJS issues a signed JWT containing the `user_id` and `role`.
  3. Client attaches `Authorization: Bearer <token>` to all subsequent requests.
* **Internal Trust:** The JWT secret is shared securely (via Vault or environment variables) between NestJS and Python, allowing both services to independently verify token authenticity without querying the database.

## 6. Core Workflow: The "Validate Before Persist" Sequence
This sequence ensures data integrity by preventing invalid states (e.g., false online statuses) from caching.
1. **Request Initiation:** The client sends a "Punch In" request with GPS coordinates to the NestJS API.
2. **Identity Verification:** NestJS validates the JWT and confirms the user exists in PostgreSQL.
3. **Synchronous Hand-off:** NestJS pauses its execution and makes a synchronous internal API call to Python, passing the payload (`user_id`, `coords`, timestamp).
4. **Intelligence Validation:** Python checks the GPS coordinates against the required geofence and verifies the user's current shift in the Postgres hierarchy.
5. **Resolution:**
   * **If Invalid:** Python returns a failure flag. NestJS immediately returns an HTTP 400 error to the client. No databases are updated.
   * **If Valid:** Python returns a success flag.
6. **State & Persistence Update:** NestJS updates the Redis state to online and dispatches the raw log to MongoDB for historical storage.
7. **Async Broadcast:** NestJS pushes an event to the Redis Pub/Sub channel, instantly updating the Manager Dashboard UI via WebSockets.

## 7. The Logical Connection Map (Data Mapping)

The databases are connected through Data Mapping at the Application Layer (NestJS and Python code) using a single universal anchor: the User UUID.

```text
  [ PostgreSQL ] (Relational/Structure)
   └── table: users
        └── id: UUID "550e8400-e29b-41d4-a716-446655440000" <──┐ (The Core Anchor)
                                                               │
  [ MongoDB ] (Document/Logs)                                 │
   └── collection: attendance_logs                             │
        └── document: {                                        │
              user_id: "550e8400-e29b-41d4-a716-446655440000" ─┼─── [Joined by Code]
              timestamp: ISODate("2026-07-13T..."),            │
              action: "PUNCH_IN"                               │
            }                                                  │
                                                               │
  [ Redis ] (In-Memory/Live State)                             │
   └── key: "user:status:550e8400-e29b-41d4-a716-446655440000" ┘
        └── value: "online"
```

### Application Joins
When generating reports showing a manager their team's data along with current status, the backend performs Application-Level Joins:
1. NestJS queries PostgreSQL to traverse the hierarchy tree and get subordinate `user_id`s.
2. NestJS uses those `user_id`s to query Redis (e.g., MGET) to instantly append live statuses.
3. Python uses those `user_id`s to query MongoDB (using `$in` operator) for historical logs.

### Maintaining Data Integrity
* **PostgreSQL is the Parent:** A UUID must exist in PostgreSQL before it can be used in MongoDB or Redis.
* **Cascading Deletes/Archiving:** If a user is deleted from PostgreSQL, application code triggers an async background worker to clean up/archive the user's logs in MongoDB and wipe keys from Redis.

## Agent Instructions & Strict Rules
1. **Syntax Only:** The AI agent acts solely as a syntax writer, following the user's logic precisely.
2. **No Unapproved Logic:** The agent will not insert arbitrary logic. Architectural decisions must be approved by the user. The agent can only offer suggestions.
3. **Work Logs:** A `CHANGELOG.md` (or `WORK_LOG.md`) will be maintained and updated only right before a git commit, strictly upon the user's request.
4. **API Documentation:** A separate `API_DOCS.md` will track all endpoints, routes, and JSON schemas.
