export type Role = 'client' | 'master' | 'operator' | 'manager' | 'administrator';

export interface AppError extends Error {
  status?: number;
  code?: string;
  retryable?: boolean;
  details?: unknown[];
}

export function asAppError(value: unknown): AppError {
  return value instanceof Error ? value as AppError : new Error(String(value));
}

export interface Product {
  id: string;
  name: string;
  category: string;
  price: number;
  unit: string;
  emoji: string;
  description: string;
  tag: string;
  stock: Record<string, number>;
}

export interface ProjectStep {
  id: string;
  title: string;
  days: number;
  after?: string[];
  order?: number;
}

export interface Scenario {
  id: string;
  title: string;
  subtitle: string;
  emoji: string;
  room: string;
  keywords: string[];
  defaultBudget: number;
  area: number;
  service: number;
  requirements: Array<[string, number]>;
  tool: string;
  steps: ProjectStep[];
  warn: string;
}

export interface InventoryItem {
  id: string;
  productId: string | null;
  name: string;
  qty: number;
}

export interface CartItem {
  id: string;
  productId: string;
  quantity: number;
}

export interface User {
  id: string;
  name: string;
  roles: Role[];
  city: string;
  district: string;
  kind: string;
  homeType: string;
  area: number;
  rooms: number;
  roomAreas: Record<string, number>;
  address: string;
  inventory: InventoryItem[];
  cart: CartItem[];
  projectIds: string[];
  orderIds: string[];
  groupIds: string[];
  forgeVotes: string[];
  pulseSubscriptions: string[];
  createdAt: string;
}

export interface PlanItem {
  productId: string;
  name: string;
  emoji: string;
  unit: string;
  price: number;
  needed: number;
  owned: number;
  purchase: number;
  subtotal: number;
  stock: number;
  available: boolean;
}

export interface PlanOption {
  id: 'diy' | 'hybrid' | 'pro';
  title: string;
  materials: number;
  rental: number;
  service: number;
  total: number;
  note: string;
}

export interface PlanWarning {
  level: 'critical' | 'warning' | 'info';
  title: string;
  detail: string;
}

export interface Plan {
  id: string;
  scenarioId: string;
  title: string;
  subtitle: string;
  emoji: string;
  task: string;
  room: string;
  area: number;
  budget: number;
  mode: PlanOption['id'];
  city: string;
  items: PlanItem[];
  options: PlanOption[];
  selected: PlanOption;
  estimated: number;
  materials: number;
  service: number;
  rental: number;
  saved: number;
  steps: ProjectStep[];
  warnings: PlanWarning[];
  alternatives: string[];
  flagged: boolean;
  scale: number;
  createdAt: string;
  disclaimer: string;
  ruleVersion?: string;
  calculationId?: string;
}

export interface ProofObject {
  key: string;
  mime: string;
  size: number;
  storage: 'local' | 's3';
}

export interface ProjectProof {
  checklist: boolean[];
  note: string;
  object?: ProofObject | null;
  image?: string | null;
  verified: string;
  date: string;
}

export interface Project {
  id: string;
  userId: string;
  title: string;
  scenarioId: string;
  room: string;
  area?: number;
  createdAt: string;
  status: string;
  budget: number;
  estimated: number;
  ruleVersion?: string;
  plan: Plan | null;
  proof: ProjectProof | null;
}

export interface OrderItem {
  productId: string;
  name: string;
  price: number;
  quantity: number;
  quotedPrice: number;
}

export interface Order {
  id: string;
  userId: string;
  reservationId: string;
  items: OrderItem[];
  total: number;
  city: string;
  status: string;
  createdAt: string;
  notice: string;
}

export interface Group {
  id: string;
  title: string;
  district: string;
  city: string;
  category: string;
  participants: number;
  memberIds: string[];
  target: number;
  basePrice: number;
  description: string;
  date: string;
}

export interface DnaTemplate {
  id: string;
  scenarioId: string;
  name: string;
  homeType: string;
  room: string;
  area: number;
  cost: number;
  uses: number;
  verified: boolean;
  description: string;
  products: string[];
  city: string;
}

export interface ForgeItem {
  id: string;
  name: string;
  emoji: string;
  description: string;
  category: string;
  interested: number;
  voters: string[];
  threshold: number;
  approved: boolean;
  unitPrice: number;
  productIds: string[];
}

export interface PulseItem {
  id: string;
  name: string;
  category: string;
  model: string;
  verifiedCases: number;
  reportedCases: number;
  match: string;
  recommendation: string;
  level: string;
  source: string;
  linkedProducts: string[];
}

export interface PulseReport {
  id: string;
  userId: string;
  category: string;
  model: string;
  symptom: string;
  status: string;
  verified: boolean;
  createdAt: string;
}

export interface Calculation {
  id: string;
  userId: string;
  input: Record<string, unknown>;
  plan: Plan;
  rulesVersion: string;
  createdAt: string;
  expiresAt: string;
}

export interface ReservationItem {
  productId: string;
  quantity: number;
  quotedPrice: number;
}

export interface Reservation {
  id: string;
  userId: string;
  city: string;
  items: ReservationItem[];
  status: 'active' | 'expired' | 'replaced' | 'cancelled' | 'consumed';
  createdAt: string;
  expiresAt: string;
  consumedAt?: string;
}

export interface AppState {
  version: number;
  users: User[];
  products: Product[];
  projects: Project[];
  orders: Order[];
  groups: Group[];
  templates: DnaTemplate[];
  forge: ForgeItem[];
  pulse: PulseItem[];
  reports: PulseReport[];
  calculations: Calculation[];
  reservations: Reservation[];
  createdAt: string;
}
