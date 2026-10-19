export interface VerifiedIdentity {
  googleSubject: string;
  email: string;
  displayName: string;
}

export interface IdentityVerifier {
  verify(idToken: string): Promise<VerifiedIdentity>;
}

export interface Account {
  id: string;
  email: string;
  displayName: string;
}

export interface Session {
  id: string;
  userId: string;
  familyId: string;
  expiresAt: Date;
}

export type Rotation = {kind: 'ok'; session: Session} | {kind: 'invalid' | 'replayed'};

export interface AuthRepository {
  login(identity: VerifiedIdentity, refreshHash: Buffer, now: Date, expiresAt: Date): Promise<{account: Account; session: Session}>;
  rotate(refreshHash: Buffer, nextHash: Buffer, now: Date): Promise<Rotation>;
  activeSession(sessionId: string, userId: string, now: Date): Promise<Session | null>;
  account(userId: string): Promise<Account | null>;
  revokeFamily(userId: string, familyId: string, now: Date): Promise<void>;
  deleteAccount(userId: string): Promise<void>;
}
