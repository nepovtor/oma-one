export type ShelfSurface = 'unknown' | 'concrete' | 'drywall' | 'wood';
export type ShelfFastener = 'none' | 'concreteAnchor' | 'drywallAnchor' | 'woodScrew';
export type ShelfReadiness = 'incomplete' | 'blocked' | 'review' | 'candidate';
export type ShelfSafetyStatus = 'BLOCKED' | 'REVIEW' | 'PRELIMINARY_PASS';
export type ShelfProofStatus = 'IN_PROGRESS' | 'SELF_REPORTED' | 'EVIDENCE_SUBMITTED' | 'EXPERT_VERIFIED';

export interface ShelfDraft {
  version: 1;
  id: string;
  wall: ShelfSurface;
  shelfWeightKg: number;
  plannedLoadKg: number;
  fastener: ShelfFastener;
  utilitiesChecked: boolean;
  wallInspected: boolean;
  manufacturerInstructionsChecked: boolean;
  ownedQuantities: Record<string, number>;
  completedStepIDs: string[];
  photoDataUrl: string | null;
  photoHash: string | null;
  localCartProductIDs: string[];
  localCartQuantities: Record<string,number>;
  updatedAt: string;
}

export interface ShelfProduct {
  id: string;
  name: string;
  price: number;
  unit?: string;
}

export interface ShelfBasketItem {
  id: string;
  name: string;
  required: number;
  owned: number;
  toBuy: number;
  unitPrice: number;
  pay: number;
}

export interface ShelfEvaluation {
  status: ShelfSafetyStatus;
  readiness: ShelfReadiness;
  totalLoadKg: number;
  critical: string[];
  risks: string[];
  basket: ShelfBasketItem[];
  full: number;
  total: number;
  savings: number;
  candidateProductIDs: string[];
  proofStatus: ShelfProofStatus;
}

export const SHELF_STORAGE_KEY = 'oma-one-shelf-v1';
interface BrowserShelfEngine {
  version: string;
  steps: Array<{id: string; title: string; after: string[]}>;
  evaluate(inputJSON: string): string;
  canComplete(completedJSON: string, stepId: string): boolean;
  toggle(completedJSON: string, stepId: string): string;
}

declare global {
  var omaShelfEngine: BrowserShelfEngine | undefined;
}

const shelfEngine = (): BrowserShelfEngine => {
  if (!globalThis.omaShelfEngine) throw new Error('Единый движок правил полки не загружен');
  return globalThis.omaShelfEngine;
};

export const SHELF_STEPS = shelfEngine().steps;
const fastenerEngineID: Record<ShelfFastener, string> = {
  none: 'unknown',
  concreteAnchor: 'concrete-anchor',
  drywallAnchor: 'drywall-anchor',
  woodScrew: 'wood-screw'
};

const clampQuantity = (value: unknown) => {
  const quantity = Number(value);
  return Number.isFinite(quantity) ? Math.max(0, Math.min(100, Math.floor(quantity))) : 0;
};

const clampWeight = (value: unknown) => {
  const weight = Number(value);
  return Number.isFinite(weight) ? Math.max(0, Math.min(1000, Math.round(weight * 10) / 10)) : 0;
};

export function createShelfDraft(now = new Date()): ShelfDraft {
  return {
    version: 1,
    id: globalThis.crypto?.randomUUID?.() ?? `shelf-${now.getTime()}`,
    wall: 'unknown',
    shelfWeightKg: 0,
    plannedLoadKg: 0,
    fastener: 'none',
    utilitiesChecked: false,
    wallInspected: false,
    manufacturerInstructionsChecked: false,
    ownedQuantities: {},
    completedStepIDs: [],
    photoDataUrl: null,
    photoHash: null,
    localCartProductIDs: [],
    localCartQuantities: {},
    updatedAt: now.toISOString()
  };
}

export function normalizeShelfDraft(value: unknown): ShelfDraft {
  const fallback = createShelfDraft();
  if (!value || typeof value !== 'object') return fallback;
  const input = value as Partial<ShelfDraft>;
  const surfaces: ShelfSurface[] = ['unknown', 'concrete', 'drywall', 'wood'];
  const fasteners: ShelfFastener[] = ['none', 'concreteAnchor', 'drywallAnchor', 'woodScrew'];
  const stepIDs = new Set(SHELF_STEPS.map(step => step.id));
  const owned = input.ownedQuantities && typeof input.ownedQuantities === 'object'
    ? Object.fromEntries(Object.entries(input.ownedQuantities).map(([id, quantity]) => [id, clampQuantity(quantity)]))
    : {};
  return {
    ...fallback,
    id: typeof input.id === 'string' && input.id ? input.id.slice(0, 100) : fallback.id,
    wall: surfaces.includes(input.wall as ShelfSurface) ? input.wall as ShelfSurface : 'unknown',
    shelfWeightKg: clampWeight(input.shelfWeightKg),
    plannedLoadKg: clampWeight(input.plannedLoadKg),
    fastener: fasteners.includes(input.fastener as ShelfFastener) ? input.fastener as ShelfFastener : 'none',
    utilitiesChecked: input.utilitiesChecked === true,
    wallInspected: input.wallInspected === true,
    manufacturerInstructionsChecked: input.manufacturerInstructionsChecked === true,
    ownedQuantities: owned,
    completedStepIDs: Array.isArray(input.completedStepIDs)
      ? [...new Set(input.completedStepIDs.filter((id): id is string => typeof id === 'string' && stepIDs.has(id as typeof SHELF_STEPS[number]['id'])))]
      : [],
    photoDataUrl: typeof input.photoDataUrl === 'string' && input.photoDataUrl.startsWith('data:image/') ? input.photoDataUrl : null,
    photoHash: typeof input.photoHash === 'string' && /^[a-f0-9]{64}$/.test(input.photoHash) ? input.photoHash : null,
    localCartProductIDs: Array.isArray(input.localCartProductIDs)
      ? [...new Set(input.localCartProductIDs.filter(id => typeof id === 'string'))]
      : [],
    localCartQuantities:Object.fromEntries((Array.isArray(input.localCartProductIDs)?input.localCartProductIDs:[]).filter((id):id is string=>typeof id==='string').map(id=>{
      const q=Number(input.localCartQuantities?.[id]??1);
      return [id,Number.isInteger(q)?Math.max(1,Math.min(200,q)):1];
    })),
    updatedAt: typeof input.updatedAt === 'string' ? input.updatedAt : fallback.updatedAt
  };
}

export function evaluateShelf(draftInput: ShelfDraft, products: ShelfProduct[]): ShelfEvaluation {
  const draft = normalizeShelfDraft(draftInput);
  const photoHashes = draft.photoDataUrl && draft.photoHash ? [draft.photoHash] : [];
  const output = JSON.parse(shelfEngine().evaluate(JSON.stringify({
    projectId: draft.id,
    surface: draft.wall,
    fastener: fastenerEngineID[draft.fastener],
    shelfWeightKg: draft.shelfWeightKg,
    plannedLoadKg: draft.plannedLoadKg,
    wallInspected: draft.wallInspected,
    verifiedWiring: draft.utilitiesChecked,
    manufacturerInstructionsChecked: draft.manufacturerInstructionsChecked,
    products: products.map(product => ({id: product.id, name: product.name, unitPrice: product.price})),
    inventory: Object.entries(draft.ownedQuantities).map(([id, qty]) => ({id, qty})),
    completedStepIds: draft.completedStepIDs,
    photoHashes
  }))) as {
    result: {
      readiness: ShelfReadiness;
      totalLoadKg: number;
      candidateProductIds: string[];
      antiFail: {status: ShelfSafetyStatus; critical: string[]; risk: string[]};
      zeroBuy: {items: ShelfBasketItem[]; full: number; after: number; savings: number};
      proof: {status: ShelfProofStatus};
    };
  };
  const result = output.result;
  return {
    status: result.antiFail.status,
    readiness: result.readiness,
    totalLoadKg: result.totalLoadKg,
    critical: result.antiFail.critical,
    risks: result.antiFail.risk,
    basket: result.zeroBuy.items,
    full: result.zeroBuy.full,
    total: result.zeroBuy.after,
    savings: result.zeroBuy.savings,
    candidateProductIDs: result.candidateProductIds,
    proofStatus: result.proof.status
  };
}

export function canCompleteShelfStep(draftInput: ShelfDraft, stepID: string): boolean {
  const draft = normalizeShelfDraft(draftInput);
  return shelfEngine().canComplete(JSON.stringify(draft.completedStepIDs), stepID);
}

export function toggleShelfStep(draftInput: ShelfDraft, stepID: string): ShelfDraft {
  const draft = normalizeShelfDraft(draftInput);
  draft.completedStepIDs = JSON.parse(shelfEngine().toggle(JSON.stringify(draft.completedStepIDs), stepID)) as string[];
  draft.updatedAt = new Date().toISOString();
  return draft;
}

export function loadShelfDraft(storage: Pick<Storage, 'getItem'> = localStorage): ShelfDraft {
  try {
    const raw = storage.getItem(SHELF_STORAGE_KEY);
    return raw ? normalizeShelfDraft(JSON.parse(raw)) : createShelfDraft();
  } catch {
    return createShelfDraft();
  }
}

export function saveShelfDraft(draftInput: ShelfDraft, storage: Pick<Storage, 'setItem'> = localStorage): ShelfDraft {
  const draft = normalizeShelfDraft({...draftInput, updatedAt: new Date().toISOString()});
  storage.setItem(SHELF_STORAGE_KEY, JSON.stringify(draft));
  return draft;
}
