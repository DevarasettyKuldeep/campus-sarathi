import { z } from 'zod';

const environmentSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  HOST: z.string().trim().min(1).default('127.0.0.1'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  DATABASE_URL: z.string().url().refine((value) => {
    const protocol = new URL(value).protocol;
    return protocol === 'postgresql:' || protocol === 'postgres:';
  }, 'Use a PostgreSQL connection URL.').optional(),
  GOOGLE_CLIENT_IDS: z.string().transform((value) => value.split(',').map((id) => id.trim()))
    .pipe(z.array(z.string().regex(/^[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$/)).min(1)).optional(),
  AUTH_SIGNING_KEY: z.string().regex(/^[A-Za-z0-9_-]+$/)
    .refine((value) => Buffer.from(value, 'base64url').length >= 32,
      'Use a generated signing key of at least 32 random bytes.').optional(),
}).superRefine((value, context) => {
  if (value.NODE_ENV === 'production') {
    for (const key of ['DATABASE_URL', 'GOOGLE_CLIENT_IDS', 'AUTH_SIGNING_KEY'] as const) {
      if (!value[key]) context.addIssue({code: 'custom', path: [key], message: 'Required in production.'});
    }
  }
  if (value.AUTH_SIGNING_KEY || value.GOOGLE_CLIENT_IDS) {
    for (const key of ['DATABASE_URL', 'GOOGLE_CLIENT_IDS', 'AUTH_SIGNING_KEY'] as const) {
      if (!value[key]) context.addIssue({code: 'custom', path: [key], message: 'Required to enable sign-in.'});
    }
  }
});

export type Environment = z.infer<typeof environmentSchema>;

/** Report field names only: Zod issues may otherwise include secret input. */
export function readEnvironment(input: Record<string, string | undefined>): Environment {
  const parsed = environmentSchema.safeParse(input);
  if (!parsed.success) {
    const names = [...new Set(parsed.error.issues.map((issue) => issue.path.join('.')))];
    throw new Error(`Invalid environment fields: ${names.join(', ')}`);
  }
  return parsed.data;
}
