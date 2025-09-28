import { User } from '../models/user.model';

export const USERS: User[] = [
  { username: 'alice', displayName: 'Alice Rivera', role: 'user' },
  { username: 'bob',   displayName: 'Bob Ortega',  role: 'user' },
  { username: 'guest', displayName: 'Guest',       role: 'viewer' },
  { username: 'admin', displayName: 'Administrator', role: 'admin' }
];

// Optional default demo password for FE-only validation before calling backend.
// NOTE: Backend currently accepts admin/ChangeMe123!; others may 401 until you extend API.
export const PASSWORDS: Record<string, string> = {
  alice: 'demo123',
  bob:   'demo123',
  guest: 'guest',
  admin: 'ChangeMe123!'
};
