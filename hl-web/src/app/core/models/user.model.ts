import { Role } from './role.type';

export interface User {
  username: string;
  displayName: string;
  role: Role;
}
