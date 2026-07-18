# CHANGELOG

This document tracks incremental work done on the Polyglot Attendance & Seniority Tracker project before each commit.
It is updated strictly upon the user's request prior to a git commit.

## [Unreleased]
- Initialized `.gitignore` with boilerplate for Node.js/Next.js, Python, Java, Go, OS, and environment files.
- Created `ARCHITECTURE.md` to persist architecture blueprints and rules.
- Created `API_DOCS.md` to track API endpoints.
- Created `CHANGELOG.md` to track work done before commits.
- Created `DATABASE_DESIGN.md` as a living conceptual schema document.
- Scaffolded NestJS application in `pure-api-backend/core`.
- Installed and configured Prisma, Redis (`ioredis`), JWT auth, and validation packages.
- Cleaned NestJS boilerplate (`app.controller.ts`, `app.service.ts`).
- Created initial `README.md` at root.
- Created `schema.prisma` from raw PostgreSQL definitions and instantiated the schema in Neon via `npx prisma migrate dev`.
- Generated raw TypeScript Prisma client (`client.ts`) with `typedSql` output configuration.
- Replaced direct Prisma usage with NestJS Dependency Injection via `TruthDBModule` and `TruthDBService`.
- Added NestJS Middleware Request Lifecycle (Guards, Interceptors, Pipes, Filters) documentation to `ARCHITECTURE.md`.
- Added `.env.example` as a template for securely passing connection strings.
