CREATE TABLE "subjects" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "code" VARCHAR(50) NOT NULL,
  "name" VARCHAR(200) NOT NULL,
  "revision" INTEGER NOT NULL DEFAULT 1,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "subjects_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "subjects_user_id_fkey" FOREIGN KEY ("user_id")
    REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "subjects_user_code_key" UNIQUE ("user_id", "code"),
  CONSTRAINT "subjects_user_id_key" UNIQUE ("user_id", "id"),
  CONSTRAINT "subjects_code_len" CHECK (length(trim("code")) BETWEEN 1 AND 50),
  CONSTRAINT "subjects_name_len" CHECK (length(trim("name")) BETWEEN 1 AND 200)
);

CREATE TABLE "courses" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "subject_id" UUID NOT NULL,
  "semester_label" VARCHAR(50) NOT NULL,
  "credits" INTEGER,
  "attendance_threshold" DECIMAL(5, 2),
  "revision" INTEGER NOT NULL DEFAULT 1,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "courses_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "courses_user_id_fkey" FOREIGN KEY ("user_id")
    REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "courses_user_subject_fkey" FOREIGN KEY ("user_id", "subject_id")
    REFERENCES "subjects"("user_id", "id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "courses_user_subject_semester_key" UNIQUE ("user_id", "subject_id", "semester_label"),
  CONSTRAINT "courses_user_id_key" UNIQUE ("user_id", "id"),
  CONSTRAINT "courses_credits_check" CHECK ("credits" IS NULL OR ("credits" >= 0 AND "credits" <= 30)),
  CONSTRAINT "courses_attendance_threshold_check" CHECK (
    "attendance_threshold" IS NULL OR ("attendance_threshold" > 0 AND "attendance_threshold" <= 100)
  )
);

CREATE TABLE "class_schedules" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "course_id" UUID,
  "subject_name" VARCHAR(200) NOT NULL,
  "weekday" SMALLINT NOT NULL,
  "start_minute" SMALLINT NOT NULL,
  "end_minute" SMALLINT NOT NULL,
  "room" VARCHAR(200) NOT NULL,
  "source" VARCHAR(50) NOT NULL DEFAULT 'student',
  "revision" INTEGER NOT NULL DEFAULT 1,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "class_schedules_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "class_schedules_user_id_fkey" FOREIGN KEY ("user_id")
    REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "class_schedules_user_course_fkey" FOREIGN KEY ("user_id", "course_id")
    REFERENCES "courses"("user_id", "id") ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT "class_schedules_weekday_check" CHECK ("weekday" BETWEEN 1 AND 7),
  CONSTRAINT "class_schedules_time_check" CHECK (
    "start_minute" >= 0 AND "end_minute" < 1440 AND "end_minute" > "start_minute"
  ),
  CONSTRAINT "class_schedules_room_len" CHECK (length(trim("room")) BETWEEN 1 AND 200)
);

CREATE INDEX "class_schedules_user_weekday_idx" ON "class_schedules"("user_id", "weekday");

CREATE TABLE "attendance_records" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "course_id" UUID,
  "subject_key" VARCHAR(200) NOT NULL,
  "subject_name" VARCHAR(200) NOT NULL,
  "attended" INTEGER NOT NULL,
  "conducted" INTEGER NOT NULL,
  "minimum_percentage" DECIMAL(5, 2),
  "source" VARCHAR(50) NOT NULL DEFAULT 'student',
  "revision" INTEGER NOT NULL DEFAULT 1,
  "observed_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "attendance_records_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "attendance_records_user_id_fkey" FOREIGN KEY ("user_id")
    REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "attendance_records_user_subject_source_key" UNIQUE ("user_id", "subject_key", "source"),
  CONSTRAINT "attendance_records_counts_check" CHECK (
    "attended" >= 0 AND "conducted" >= "attended" AND "conducted" <= 100000
  ),
  CONSTRAINT "attendance_records_min_pct_check" CHECK (
    "minimum_percentage" IS NULL OR ("minimum_percentage" > 0 AND "minimum_percentage" <= 100)
  )
);

CREATE TABLE "assignment_records" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "course_id" UUID,
  "subject_name" VARCHAR(200) NOT NULL,
  "title" VARCHAR(200) NOT NULL,
  "notes" TEXT,
  "due_at" TIMESTAMPTZ(3) NOT NULL,
  "completed" BOOLEAN NOT NULL DEFAULT FALSE,
  "estimated_minutes" INTEGER,
  "importance" VARCHAR(20) NOT NULL DEFAULT 'medium',
  "source" VARCHAR(50) NOT NULL DEFAULT 'student',
  "revision" INTEGER NOT NULL DEFAULT 1,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "assignment_records_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "assignment_records_user_id_fkey" FOREIGN KEY ("user_id")
    REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "assignment_records_user_course_fkey" FOREIGN KEY ("user_id", "course_id")
    REFERENCES "courses"("user_id", "id") ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT "assignment_records_title_len" CHECK (length(trim("title")) BETWEEN 1 AND 200),
  CONSTRAINT "assignment_records_est_min_check" CHECK (
    "estimated_minutes" IS NULL OR ("estimated_minutes" >= 0 AND "estimated_minutes" <= 10000)
  ),
  CONSTRAINT "assignment_records_importance_check" CHECK ("importance" IN ('low', 'medium', 'high'))
);

CREATE INDEX "assignment_records_user_status_due_idx" ON "assignment_records"("user_id", "completed", "due_at");

CREATE TABLE "announcement_records" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "scope" VARCHAR(50) NOT NULL DEFAULT 'public',
  "title" VARCHAR(250) NOT NULL,
  "body" TEXT NOT NULL,
  "origin_url" VARCHAR(500),
  "published_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "fetched_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "announcement_records_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "announcement_records_scope_pub_idx" ON "announcement_records"("scope", "published_at" DESC);

CREATE TABLE "academic_sync_receipts" (
  "user_id" UUID NOT NULL,
  "operation_id" UUID NOT NULL,
  "payload_hash" BYTEA NOT NULL,
  "result" JSONB NOT NULL,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "academic_sync_receipts_pkey" PRIMARY KEY ("user_id", "operation_id"),
  CONSTRAINT "academic_sync_receipts_user_id_fkey" FOREIGN KEY ("user_id")
    REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "academic_sync_receipts_hash" CHECK (octet_length("payload_hash") = 32),
  CONSTRAINT "academic_sync_receipts_result" CHECK (jsonb_typeof("result") = 'object')
);
