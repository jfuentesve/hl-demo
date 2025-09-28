export interface Deal {
  id: number;
  name: string;
  client: string;  // username (client == user)
  amount: number;
  createdAt: string; // ISO
}
