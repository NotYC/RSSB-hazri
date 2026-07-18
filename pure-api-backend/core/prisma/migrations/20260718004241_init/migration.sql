-- CreateTable
CREATE TABLE "users" (
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
    "sg_endpoint_id" UUID NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roles" (
    "id" UUID NOT NULL,
    "role_name" VARCHAR(255) NOT NULL,
    "desc" TEXT NOT NULL,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "permissions" (
    "id" UUID NOT NULL,
    "permission_tag" VARCHAR(255) NOT NULL,
    "desc" TEXT NOT NULL,

    CONSTRAINT "permissions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "role_permission_mapper" (
    "role_id" UUID NOT NULL,
    "permission_id" UUID NOT NULL,

    CONSTRAINT "role_permission_mapper_pkey" PRIMARY KEY ("role_id","permission_id")
);

-- CreateTable
CREATE TABLE "sg_zones" (
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(255) NOT NULL,

    CONSTRAINT "sg_zones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sg_states" (
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(255) NOT NULL,
    "zone_id" UUID NOT NULL,

    CONSTRAINT "sg_states_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sg_areas" (
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(255) NOT NULL,
    "state_id" UUID NOT NULL,

    CONSTRAINT "sg_areas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sg_centers" (
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(255) NOT NULL,
    "n_cord" VARCHAR(255) NOT NULL,
    "e_cord" VARCHAR(255) NOT NULL,
    "address" TEXT NOT NULL,
    "area_id" UUID NOT NULL,

    CONSTRAINT "sg_centers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sg_endpoints" (
    "id" UUID NOT NULL,
    "type" VARCHAR(255) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(255) NOT NULL,
    "n_cord" VARCHAR(255) NOT NULL,
    "e_cord" VARCHAR(255) NOT NULL,
    "address" TEXT NOT NULL,
    "center_id" UUID NOT NULL,

    CONSTRAINT "sg_endpoints_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sewa_catalog" (
    "id" UUID NOT NULL,
    "tag" VARCHAR(255) NOT NULL,
    "name" VARCHAR(255) NOT NULL,

    CONSTRAINT "sewa_catalog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sewadar_details" (
    "user_id" UUID NOT NULL,
    "batch_id" VARCHAR(255) NOT NULL,
    "category_id" UUID NOT NULL,
    "apply_date" TIMESTAMPTZ(0) NOT NULL,
    "join_date" TIMESTAMPTZ(0) NOT NULL,

    CONSTRAINT "sewadar_details_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "moderator_details" (
    "user_id" UUID NOT NULL,
    "mod_id" UUID NOT NULL,
    "category_id" UUID NOT NULL,
    "apply_date" TIMESTAMPTZ(0) NOT NULL,
    "join_date" TIMESTAMPTZ(0) NOT NULL,

    CONSTRAINT "moderator_details_pkey" PRIMARY KEY ("user_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "roles_role_name_key" ON "roles"("role_name");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_role_fkey" FOREIGN KEY ("role") REFERENCES "roles"("role_name") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_sg_endpoint_id_fkey" FOREIGN KEY ("sg_endpoint_id") REFERENCES "sg_endpoints"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role_permission_mapper" ADD CONSTRAINT "role_permission_mapper_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role_permission_mapper" ADD CONSTRAINT "role_permission_mapper_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "permissions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sg_states" ADD CONSTRAINT "sg_states_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "sg_zones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sg_areas" ADD CONSTRAINT "sg_areas_state_id_fkey" FOREIGN KEY ("state_id") REFERENCES "sg_states"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sg_centers" ADD CONSTRAINT "sg_centers_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "sg_areas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sg_endpoints" ADD CONSTRAINT "sg_endpoints_center_id_fkey" FOREIGN KEY ("center_id") REFERENCES "sg_centers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sewadar_details" ADD CONSTRAINT "sewadar_details_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sewadar_details" ADD CONSTRAINT "sewadar_details_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "sewa_catalog"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "moderator_details" ADD CONSTRAINT "moderator_details_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "moderator_details" ADD CONSTRAINT "moderator_details_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "sewa_catalog"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
