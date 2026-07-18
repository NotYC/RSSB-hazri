-- =============================================================
-- Polyglot Attendance & Seniority Tracker — PostgreSQL Schema
-- Cleaned from drawSQL export (2026-07-14)
-- Covers: Users / Roles / Permissions / SG hierarchy / Sewadar & Moderator details
-- =============================================================

CREATE TABLE "users"(
    "id" UUID NOT NULL,
    "firstname" VARCHAR(255) NOT NULL,
    "lastname" VARCHAR(255) NOT NULL,
    "phone_number" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "aadhar_number" BIGINT NOT NULL,
    "profile_pic" VARCHAR(255) NOT NULL,
    "role" VARCHAR(255) NOT NULL,
    "adr_house" VARCHAR(255) NOT NULL,
    "adr_area" VARCHAR(255) NOT NULL,
    "adr_city" VARCHAR(255) NOT NULL,
    "adr_state" VARCHAR(255) NOT NULL,
    "adr_pincode" VARCHAR(255) NOT NULL,
    "is_approved" BOOLEAN NOT NULL,
    "sg_endpoint_id" UUID NOT NULL
);
ALTER TABLE
    "users" ADD PRIMARY KEY("id");

CREATE TABLE "roles"(
    "id" UUID NOT NULL,
    "role_name" VARCHAR(255) NOT NULL,
    "desc" TEXT NOT NULL
);
ALTER TABLE
    "roles" ADD PRIMARY KEY("id");
-- Changed from a plain index to UNIQUE: users.role references roles.role_name,
-- and Postgres requires the FK target column to be UNIQUE or a PRIMARY KEY.
ALTER TABLE
    "roles" ADD CONSTRAINT "roles_role_name_unique" UNIQUE("role_name");

CREATE TABLE "permissions"(
    "id" UUID NOT NULL,
    "permission_tag" VARCHAR(255) NOT NULL,
    "desc" TEXT NOT NULL
);
ALTER TABLE
    "permissions" ADD PRIMARY KEY("id");

CREATE TABLE "role_permission_mapper"(
    "role_id" UUID NOT NULL,
    "permission_id" UUID NOT NULL
);
-- Fixed: was two separate ADD PRIMARY KEY calls, which Postgres rejects
-- (a table can only have one primary key). This is now a single composite key.
ALTER TABLE
    "role_permission_mapper" ADD PRIMARY KEY("role_id", "permission_id");

CREATE TABLE "sg_zones"(
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "sg_zones" ADD PRIMARY KEY("id");

CREATE TABLE "sg_states"(
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(255) NOT NULL,
    "zone_id" UUID NOT NULL
);
ALTER TABLE
    "sg_states" ADD PRIMARY KEY("id");

CREATE TABLE "sg_areas"(
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(255) NOT NULL,
    "state_id" UUID NOT NULL
);
ALTER TABLE
    "sg_areas" ADD PRIMARY KEY("id");

CREATE TABLE "sg_centers"(
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(255) NOT NULL,
    "n_cord" VARCHAR(255) NOT NULL,
    "e_cord" VARCHAR(255) NOT NULL,
    "address" TEXT NOT NULL,
    "area_id" UUID NOT NULL
);
ALTER TABLE
    "sg_centers" ADD PRIMARY KEY("id");

CREATE TABLE "sg_endpoints"(
    "id" UUID NOT NULL,
    "type" VARCHAR(255) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(255) NOT NULL,
    "n_cord" VARCHAR(255) NOT NULL,
    "e_cord" VARCHAR(255) NOT NULL,
    "address" TEXT NOT NULL,
    "center_id" UUID NOT NULL
);
ALTER TABLE
    "sg_endpoints" ADD PRIMARY KEY("id");

CREATE TABLE "sewa_catalog"(
    "id" UUID NOT NULL,
    "tag" VARCHAR(255) NOT NULL,
    "name" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "sewa_catalog" ADD PRIMARY KEY("id");

CREATE TABLE "sewadar_details"(
    "user_id" UUID NOT NULL,
    "batch_id" VARCHAR(255) NOT NULL,
    "category_id" UUID NOT NULL,
    "apply_date" TIMESTAMP(0) WITH TIME ZONE NOT NULL,
    "join_date" TIMESTAMP(0) WITH TIME ZONE NOT NULL
);
ALTER TABLE
    "sewadar_details" ADD PRIMARY KEY("user_id");

CREATE TABLE "moderator_details"(
    "user_id" UUID NOT NULL,
    "mod_id" UUID NOT NULL,
    "category_id" UUID NOT NULL,
    "apply_date" TIMESTAMP(0) WITH TIME ZONE NOT NULL,
    "join_date" TIMESTAMP(0) WITH TIME ZONE NOT NULL
);
ALTER TABLE
    "moderator_details" ADD PRIMARY KEY("user_id");

-- ===================== Foreign Keys =====================

ALTER TABLE
    "sg_states" ADD CONSTRAINT "sg_states_zone_id_foreign" FOREIGN KEY("zone_id") REFERENCES "sg_zones"("id");
ALTER TABLE
    "sg_areas" ADD CONSTRAINT "sg_areas_state_id_foreign" FOREIGN KEY("state_id") REFERENCES "sg_states"("id");
ALTER TABLE
    "sg_centers" ADD CONSTRAINT "sg_centers_area_id_foreign" FOREIGN KEY("area_id") REFERENCES "sg_areas"("id");
ALTER TABLE
    "sg_endpoints" ADD CONSTRAINT "sg_endpoints_center_id_foreign" FOREIGN KEY("center_id") REFERENCES "sg_centers"("id");

ALTER TABLE
    "users" ADD CONSTRAINT "users_role_foreign" FOREIGN KEY("role") REFERENCES "roles"("role_name");
ALTER TABLE
    "users" ADD CONSTRAINT "users_sg_endpoint_id_foreign" FOREIGN KEY("sg_endpoint_id") REFERENCES "sg_endpoints"("id");

ALTER TABLE
    "role_permission_mapper" ADD CONSTRAINT "role_permission_mapper_role_id_foreign" FOREIGN KEY("role_id") REFERENCES "roles"("id");
ALTER TABLE
    "role_permission_mapper" ADD CONSTRAINT "role_permission_mapper_permission_id_foreign" FOREIGN KEY("permission_id") REFERENCES "permissions"("id");

ALTER TABLE
    "sewadar_details" ADD CONSTRAINT "sewadar_details_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "users"("id");
ALTER TABLE
    "sewadar_details" ADD CONSTRAINT "sewadar_details_category_id_foreign" FOREIGN KEY("category_id") REFERENCES "sewa_catalog"("id");

ALTER TABLE
    "moderator_details" ADD CONSTRAINT "moderator_details_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "users"("id");
ALTER TABLE
    "moderator_details" ADD CONSTRAINT "moderator_details_category_id_foreign" FOREIGN KEY("category_id") REFERENCES "sewa_catalog"("id");
