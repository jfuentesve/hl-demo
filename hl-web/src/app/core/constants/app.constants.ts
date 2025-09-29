import { User } from '../models/user.model';

export const USERS: User[] = [
  { username: 'alice', firstName: 'Alice', lastName: 'Copper', role: 'user', client: 'Acme Corp' },
  { username: 'bob',   firstName: 'Bob',   lastName: 'Ortega', role: 'user', client: 'Globex LLC' },
  { username: 'guest', firstName: 'Gale',  lastName: 'Guest',  role: 'viewer', client: 'Public' },
  { username: 'admin', firstName: 'Avery', lastName: 'Admin',  role: 'admin', client: 'Corporate HQ' }
];

// Optional default demo password for FE-only validation before calling backend.
// NOTE: Backend currently accepts admin/ChangeMe123!; others may 401 until you extend API.
export const PASSWORDS: Record<string, string> = {
  alice: 'demo123',
  bob:   'demo123',
  guest: 'guest',
  admin: 'ChangeMe123!'
};
