CREATE TABLE "profile_sync_receipts" (
  "user_id" UUID NOT NULL,
  "operation_id" UUID NOT NULL,
  "payload_hash" BYTEA NOT NULL,
  "result" JSONB NOT NULL,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "profile_sync_receipts_pkey" PRIMARY KEY ("user_id", "operation_id"),
  CONSTRAINT "profile_sync_receipts_user_id_fkey" FOREIGN KEY ("user_id")
    REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "profile_sync_receipts_hash" CHECK (octet_length("payload_hash") = 32),
  CONSTRAINT "profile_sync_receipts_result" CHECK (jsonb_typeof("result") = 'object')
);
