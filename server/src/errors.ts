/** Explicitly safe messages only; provider/database exceptions never use this type. */
export class AppError extends Error {
  constructor(public readonly statusCode: number, public readonly code: string, message: string) {
    super(message);
  }
}
