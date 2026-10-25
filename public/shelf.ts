export type ShelfSurface = 'unknown' | 'concrete' | 'drywall' | 'wood';
export type ShelfFastener = 'none' | 'concreteAnchor' | 'drywallAnchor' | 'woodScrew';
export type ShelfReadiness = 'incomplete' | 'blocked' | 'review' | 'candidate';
export type ShelfSafetyStatus = 'BLOCKED' | 'REVIEW' | 'PRELIMINARY_PASS';

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
  proofStatus: 'INCOMPLETE' | 'SELF_RECORDED';
}

export const SHELF_STORAGE_KEY = 'oma-one-shelf-v1';
export const SHELF_STEPS = [
  {id: 'inspect', title: 'Осмотреть стену и её состояние', after: []},
  {id: 'utilities', title: 'Проверить скрытые коммуникации', after: ['inspect']},
  {id: 'load', title: 'Уточнить вес и допустимую нагрузку', after: ['inspect']},
  {id: 'fastener', title: 'Сверить крепёж с инструкцией', after: ['utilities', 'load']},
  {id: 'mount', title: 'Выполнить монтаж', after: ['fastener']},
  {id: 'final', title: 'Проверить результат', after: ['mount']}
] as const;

const surfaceFastener: Record<Exclude<ShelfSurface, 'unknown'>, ShelfFastener> = {
  concrete: 'concreteAnchor',
  drywall: 'drywallAnchor',
  wood: 'woodScrew'
};

const fastenerProduct: Partial<Record<ShelfFastener, string>> = {
  concreteAnchor: 'p08',
  drywallAnchor: 'p09'
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
    updatedAt: typeof input.updatedAt === 'string' ? input.updatedAt : fallback.updatedAt
  };
}

export function evaluateShelf(draftInput: ShelfDraft, products: ShelfProduct[]): ShelfEvaluation {
  const draft = normalizeShelfDraft(draftInput);
  const totalLoadKg = Math.round((draft.shelfWeightKg + draft.plannedLoadKg) * 10) / 10;
  const critical: string[] = [];
  const risks: string[] = [];

  if (draft.wall === 'unknown') risks.push('Материал стены не определён. Нужен осмотр основания.');
  else if (draft.fastener !== 'none' && surfaceFastener[draft.wall] !== draft.fastener) {
    critical.push('Выбранный крепёж не соответствует указанному материалу стены.');
  }
  if (totalLoadKg > 15) risks.push('Общая нагрузка выше демонстрационного порога 15 кг. Нужна проверка специалистом.');
  if (!draft.utilitiesChecked) risks.push('Скрытые трубы и проводка не проверены. До проверки сверлить нельзя.');

  const status: ShelfSafetyStatus = critical.length ? 'BLOCKED' : risks.length ? 'REVIEW' : 'PRELIMINARY_PASS';
  const completeInputs = draft.wall !== 'unknown' && draft.shelfWeightKg > 0 && draft.plannedLoadKg > 0 && draft.fastener !== 'none';
  const fastenerID = fastenerProduct[draft.fastener];
  let readiness: ShelfReadiness = 'incomplete';
  if (completeInputs) {
    if (status === 'BLOCKED') readiness = 'blocked';
    else if (
      status === 'PRELIMINARY_PASS' &&
      totalLoadKg <= 15 &&
      draft.wallInspected &&
      draft.manufacturerInstructionsChecked &&
      Boolean(fastenerID)
    ) readiness = 'candidate';
    else readiness = 'review';
  }

  const candidateProductIDs = readiness === 'candidate' && fastenerID ? ['p07', fastenerID, 'p25'] : [];
  const inventory = new Map(Object.entries(draft.ownedQuantities).map(([id, quantity]) => [id, clampQuantity(quantity)]));
  const basket = candidateProductIDs.map(id => {
    const product = products.find(item => item.id === id);
    const required = 1;
    const owned = Math.min(required, inventory.get(id) ?? 0);
    inventory.set(id, Math.max(0, (inventory.get(id) ?? 0) - owned));
    const unitPrice = Math.max(0, Number(product?.price) || 0);
    return {id, name: product?.name ?? id, required, owned, toBuy: required - owned, unitPrice, pay: (required - owned) * unitPrice};
  });
  const full = basket.reduce((sum, item) => sum + item.required * item.unitPrice, 0);
  const total = basket.reduce((sum, item) => sum + item.pay, 0);
  const allStepsDone = SHELF_STEPS.every(step => draft.completedStepIDs.includes(step.id));

  return {
    status,
    readiness,
    totalLoadKg,
    critical,
    risks,
    basket,
    full,
    total,
    savings: full - total,
    candidateProductIDs,
    proofStatus: allStepsDone && Boolean(draft.photoDataUrl && draft.photoHash) ? 'SELF_RECORDED' : 'INCOMPLETE'
  };
}

export function canCompleteShelfStep(draftInput: ShelfDraft, stepID: string): boolean {
  const draft = normalizeShelfDraft(draftInput);
  const step = SHELF_STEPS.find(item => item.id === stepID);
  return Boolean(step && step.after.every(dependency => draft.completedStepIDs.includes(dependency)));
}

export function toggleShelfStep(draftInput: ShelfDraft, stepID: string): ShelfDraft {
  const draft = normalizeShelfDraft(draftInput);
  if (draft.completedStepIDs.includes(stepID)) {
    const blocked = new Set<string>([stepID]);
    let changed = true;
    while (changed) {
      changed = false;
      for (const step of SHELF_STEPS) {
        if (step.after.some(dependency => blocked.has(dependency)) && !blocked.has(step.id)) {
          blocked.add(step.id);
          changed = true;
        }
      }
    }
    draft.completedStepIDs = draft.completedStepIDs.filter(id => !blocked.has(id));
  } else if (canCompleteShelfStep(draft, stepID)) {
    draft.completedStepIDs = [...draft.completedStepIDs, stepID];
  }
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
