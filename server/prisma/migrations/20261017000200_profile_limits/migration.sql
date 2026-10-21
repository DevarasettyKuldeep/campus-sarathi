-- Preserve the identity migration; tighten profile invariants for the API.
ALTER TABLE "academic_profiles" ADD CONSTRAINT "academic_profiles_input_limits"
CHECK (
  "semester_number" <= 30
  AND "semester_start" >= DATE '2000-01-01'
  AND "semester_end" <= DATE '2100-12-31'
  AND "programme" !~ '[[:cntrl:]]'
);
