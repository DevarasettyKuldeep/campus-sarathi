CREATE TYPE "ConsentPurpose" AS ENUM ('ACADEMIC_PROCESSING', 'GEMINI_PROCESSING');

CREATE TABLE "users" (
  "id" UUID NOT NULL,
  "google_subject" VARCHAR(255) NOT NULL,
  "email" VARCHAR(320) NOT NULL,
  "display_name" VARCHAR(200) NOT NULL,
  "email_verified_at" TIMESTAMPTZ(3) NOT NULL,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(3) NOT NULL,
  CONSTRAINT "users_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "users_student_domain" CHECK (
    "email" = lower("email") AND "email" ~ '^[^@[:space:]]+@cb[.]students[.]amrita[.]edu$'
  ),
  CONSTRAINT "users_identity_not_blank" CHECK (
    length(trim("google_subject")) > 0 AND length(trim("display_name")) > 0
  )
);
CREATE UNIQUE INDEX "users_google_subject_key" ON "users"("google_subject");
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

CREATE TABLE "academic_profiles" (
  "user_id" UUID NOT NULL,
  "programme" VARCHAR(200) NOT NULL,
  "semester_number" INTEGER NOT NULL,
  "semester_start" DATE NOT NULL,
  "semester_end" DATE NOT NULL,
  "timezone" VARCHAR(64) NOT NULL DEFAULT 'Asia/Kolkata',
  "revision" INTEGER NOT NULL DEFAULT 1,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(3) NOT NULL,
  CONSTRAINT "academic_profiles_pkey" PRIMARY KEY ("user_id"),
  CONSTRAINT "academic_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "academic_profiles_values" CHECK (
    length(trim("programme")) > 0 AND "semester_number" >= 1 AND "revision" >= 1
    AND "semester_end" >= "semester_start" AND "timezone" = 'Asia/Kolkata'
  )
);

CREATE TABLE "sessions" (
  "id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "family_id" UUID NOT NULL,
  "refresh_hash" BYTEA NOT NULL,
  "expires_at" TIMESTAMPTZ(3) NOT NULL,
  "revoked_at" TIMESTAMPTZ(3),
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "sessions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "sessions_token_digest" CHECK (octet_length("refresh_hash") = 32),
  CONSTRAINT "sessions_expiry" CHECK ("expires_at" > "created_at")
);
CREATE UNIQUE INDEX "sessions_refresh_hash_key" ON "sessions"("refresh_hash");
CREATE INDEX "sessions_user_id_family_id_idx" ON "sessions"("user_id", "family_id");
CREATE INDEX "sessions_expires_at_idx" ON "sessions"("expires_at");

CREATE TABLE "consent_records" (
  "id" UUID NOT NULL,
  "sequence" BIGSERIAL NOT NULL,
  "user_id" UUID NOT NULL,
  "purpose" "ConsentPurpose" NOT NULL,
  "notice_version" VARCHAR(100) NOT NULL,
  "granted" BOOLEAN NOT NULL,
  "event_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "consent_records_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "consent_records_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "consent_records_notice_not_blank" CHECK (length(trim("notice_version")) > 0)
);
CREATE UNIQUE INDEX "consent_records_sequence_key" ON "consent_records"("sequence");
CREATE INDEX "consent_records_user_id_purpose_sequence_idx" ON "consent_records"("user_id", "purpose", "sequence");
