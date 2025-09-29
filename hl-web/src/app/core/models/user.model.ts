import { Role } from './role.type';

export interface User {
  username: string;
  firstName: string;
  lastName: string;
  role: Role;
  client: string;
}
