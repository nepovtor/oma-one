// Generated from proof-engine.ts. Run npm run build:ios-evidence.
// OMA ONE - deterministic, auditable, DEMO-ONLY decision prototypes (TypeScript source).
// Each function is independent of a generative model and external services.
const PROOF_VERSION = '2026-10-23-evidence.2';
const number = (v, min, max, def) => { const n = Number(v); return Number.isFinite(n) ? Math.min(max, Math.max(min, n)) : def; };
const money = (x) => Math.round((x + Number.EPSILON) * 100) / 100;
const assertArray = (v) => Array.isArray(v) ? v : [];
const idText = (x) => String(x ?? '').slice(0, 100);
const outcome = (code, what, inputs, result, explanation, limits = [], stats = {}) => ({ module: code, version: PROOF_VERSION, what, inputs, result, explanation, limits, stats, source: 'Synthetic fixtures or user-entered inputs; deterministic demo rules, never verified OMA operations' });
function zeroBuy({ requirements = [], inventory = [] } = {}) {
    const known = new Map();
    for (const i of assertArray(inventory)) {
        const k = idText(i.id);
        const q = number(i.qty, 0, 10000, 0);
        known.set(k, (known.get(k) || 0) + q);
    }
    const items = assertArray(requirements).map(r => { const id = idText(r.id), required = number(r.qty, 0, 10000, 0), owned = Math.min(required, known.get(id) || 0), unitPrice = number(r.unitPrice, 0, 1e6, 0); known.set(id, Math.max(0, (known.get(id) || 0) - owned)); return { id, name: idText(r.name || id), required, owned, toBuy: required - owned, unitPrice, saved: money(owned * unitPrice), pay: money((required - owned) * unitPrice) }; });
    const full = money(items.reduce((a, b) => a + b.required * b.unitPrice, 0)), after = money(items.reduce((a, b) => a + b.pay, 0));
    return outcome('ZeroBuy', 'Verified subtraction and no double-counting', { requirements, inventory }, { items, full, after, savings: money(full - after) }, 'Owned items are subtracted once, never below zero; savings refer to avoided demo purchase, not net lifetime savings.', ['Inventory is self-reported and does not prove suitability or condition.'], { items: items.length });
}
const compatibility = { concrete: ['concrete-anchor'], drywall: ['drywall-anchor'], wood: ['wood-screw'] };
function antiFail({ surface = 'concrete', fastener = 'concrete-anchor', loadKg = 8, verifiedWiring = false } = {}) {
    const risk = [], critical = [];
    if (!compatibility[surface])
        risk.push('Unknown wall substrate: an installer must identify it.');
    else if (!compatibility[surface].includes(fastener))
        critical.push(`Fastener ${fastener} is not mapped as compatible with ${surface}.`);
    const load = number(loadKg, 0, 1000, 8);
    if (load > 15)
        risk.push('Load above demo threshold 15 kg: professional check required.');
    if (!verifiedWiring)
        risk.push('Hidden pipes/wiring not checked. Do not drill before checking.');
    const status = critical.length ? 'BLOCKED' : risk.length ? 'REVIEW' : 'PRELIMINARY_PASS';
    return outcome('AntiFail', 'Compatibility + safety gate', { surface, fastener, loadKg: load, verifiedWiring }, { status, canAutoApprove: false, critical, risk, suggestedFasteners: compatibility[surface] || [] }, 'Rule engine never certifies a safe installation, even for a preliminary pass.', ['Illustrative compatibility map only; load limits, wall thickness and manufacturer documentation require specialist review.']);
}
const bathroomSteps = [{ id: 'inspect', name: 'Survey', after: [] }, { id: 'pipes', name: 'Pipes', after: ['inspect'] }, { id: 'waterproof', name: 'Waterproofing', after: ['pipes'] }, { id: 'tiles', name: 'Tiling', after: ['waterproof'] }, { id: 'finish', name: 'Finish and inspect', after: ['tiles'] }];
function domino({ order = ['inspect', 'pipes', 'waterproof', 'tiles', 'finish'], steps = bathroomSteps } = {}) {
    const ids = assertArray(steps).map(s => s.id), orderIds = assertArray(order).map(idText), errors = [];
    if (new Set(ids).size !== ids.length)
        errors.push('Duplicate step IDs in graph.');
    if (new Set(orderIds).size !== orderIds.length || orderIds.length !== ids.length || ids.some(id => !orderIds.includes(id)))
        errors.push('Order must contain each project step exactly once.');
    const pos = new Map(orderIds.map((s, i) => [s, i]));
    for (const s of steps)
        for (const pre of s.after || []) {
            const prerequisitePosition = pos.get(pre), stepPosition = pos.get(s.id);
            if (!ids.includes(pre))
                errors.push(`Unknown dependency: ${pre}`);
            else if (prerequisitePosition !== undefined && stepPosition !== undefined && prerequisitePosition > stepPosition)
                errors.push(`${s.id} requires ${pre} first.`);
        }
    const suggested = [], pending = new Map(steps.map(s => [s.id, s]));
    while (pending.size) {
        const ready = [...pending.values()].filter(s => (s.after || []).every(dep => suggested.includes(dep))).sort((a, b) => ids.indexOf(a.id) - ids.indexOf(b.id));
        if (!ready.length) {
            errors.push('Cyclic dependency graph.');
            break;
        }
        for (const s of ready) {
            suggested.push(s.id);
            pending.delete(s.id);
        }
    }
    return outcome('Domino', 'Topological dependency validation', { order: orderIds, steps }, { valid: errors.length === 0, errors, suggested }, 'An invalid order is rejected; the solver returns a topological order if the dependency graph is acyclic.', ['Dependency graph must be approved by a construction specialist; times/costs are not inferred.']);
}
function syncCity({ requests = [], selectedId = 'r1', sharedTripCost = 48, individualTripCost = 24, minGroup = 3 } = {}) {
    const list = assertArray(requests), selected = list.find(x => x.id === selectedId);
    if (!selected)
        return outcome('SyncCity', 'Privacy-preserving logistics match', { requests, selectedId }, { eligible: false, requestCount: 0, matchIds: [], individualTotal: 0, combinedTotal: null, savingsPerUser: 0, reason: 'Request not found' }, 'No match means no discount.');
    const matches = list.filter(x => x.city === selected.city && x.zone === selected.zone && x.slot === selected.slot && x.service === selected.service && x.id !== selectedId);
    const members = matches.length + 1, threshold = number(minGroup, 2, 20, 3), single = number(individualTripCost, 0, 2000, 24), shared = number(sharedTripCost, 0, 2000, 48);
    const eligible = members >= threshold && shared < members * single;
    const savingsPerUser = eligible ? money(single - shared / members) : 0;
    return outcome('SyncCity', 'Delivery/service bundling by zone and slot', { selectedId, sharedTripCost: shared, individualTripCost: single, minGroup: threshold }, { eligible, requestCount: members, matchIds: matches.map(x => x.id), individualTotal: money(members * single), combinedTotal: eligible ? shared : null, savingsPerUser, reason: eligible ? 'Synthetic candidate group: partner quote still required.' : 'Threshold or business case not met.' }, 'User identity and full addresses are excluded from match output; no real booking or guaranteed price.', ['No real partner pricing or participant consent exists; coordinator must validate operational feasibility.']);
}
function proof({ projectId = 'demo-p1', steps = [], photoHashes = [], inspector = null, ownerConsent = false } = {}) {
    const checklist = assertArray(steps), photos = assertArray(photoHashes).filter(x => /^[a-f0-9]{64}$/.test(String(x))).map(String), finished = checklist.length > 0 && checklist.every(x => x.done === true) && photos.length > 0;
    const professional = finished && !!inspector && inspector.approved === true && typeof inspector.id === 'string' && inspector.id.length > 0;
    const status = professional ? 'INSPECTED' : finished ? 'SELF_RECORDED' : 'INCOMPLETE';
    const attestation = { projectId: idText(projectId), checklist: checklist.map(x => ({ code: idText(x.code), done: x.done === true })), photoHashes: photos, inspector: professional ? inspector.id : null, status };
    const digest = __sha256(JSON.stringify(attestation));
    return outcome('Proof', 'Traceable evidence record, not automatic certification', { projectId, steps, photoHashesCount: photos.length, inspector: professional ? inspector.id : null, ownerConsent }, { status, digest, canPublishToDNA: professional && ownerConsent, completed: finished, photoCount: photos.length }, 'Hash identifies this exact record; user self-report is NEVER labelled professionally inspected.', ['A digest is not proof that a photo is genuine. Real uploads require metadata stripping, privacy consent and independent inspection.']);
}
function dna({ templates = [], homeType = 'panel', room = 'bath', area = 4, qtyPerM2 = 1.1 } = {}) {
    const a = number(area, 0.5, 200, 4), q = number(qtyPerM2, 1, 2, 1.1);
    const ranked = assertArray(templates).map(t => {
        const type = t.homeType === homeType, place = t.room === room, delta = Math.abs(number(t.area, 0, 200, 0) - a) / a, score = Math.max(0, Math.round((type ? 35 : 0) + (place ? 35 : 0) + Math.max(0, 30 - 50 * delta)));
        const sampleVerified = t.inspection === 'professional', candidate = score >= 70 && sampleVerified;
        return { id: t.id, score, eligible: candidate, verification: t.inspection || 'none', referenceArea: t.area, adaptedUnits: place ? Math.ceil(a * q) : null, reason: candidate ? 'Matches type, room, and professionally inspected template.' : 'Review required: similarity does not certify compatibility.' };
    }).sort((x, y) => y.score - x.score);
    return outcome('DNA', 'Ranking and room-specific adaptation', { homeType, room, area: a, qtyPerM2: q }, { templates: ranked, best: ranked[0] || null }, 'Similarity score is a DEMO ranking, not a calibrated probability or proof of engineering compatibility.', ['A real match needs dimensions, plumbing, structure, material specs, consent and moderation.'], { considered: ranked.length });
}
function forge({ projects = [], skuCosts = [], interestThreshold = 4, minGrossMargin = .15, assemblyCost = 30 } = {}) {
    const paid = assertArray(projects).filter(p => p.optIn === true), counts = {}, unique = new Set();
    for (const p of paid) {
        const k = idText(p.problem) + '|' + idText(p.homeType), participant = idText(p.userId || p.id);
        const scoped = k + '|' + participant;
        if (!participant || unique.has(scoped))
            continue;
        unique.add(scoped);
        counts[k] = (counts[k] || 0) + 1;
    }
    const clusters = Object.entries(counts).map(([key, n]) => ({ key, interested: n, threshold: interestThreshold, canPropose: n >= interestThreshold })).sort((a, b) => b.interested - a.interested);
    const netCost = money(assertArray(skuCosts).reduce((n, x) => n + number(x.cost, 0, 1e6, 0), 0) + number(assemblyCost, 0, 1e6, 30));
    const minPrice = money(netCost / (1 - number(minGrossMargin, 0, .9, .15)));
    return outcome('FORGE', 'New kit opportunity, backed by opt-in demand', { projects, interestThreshold, skuCosts, assemblyCost }, { clusters, netCost, minimumIndicativePrice: minPrice, status: 'PROPOSAL_ONLY', mayPublishPrice: false }, 'Interest is NOT an order; kit remains a proposal until buyer, category owner and supplier verify economics.', ['Gross margin excludes returns, shrinkage, marketing and overhead; all data and costs synthetic.']);
}
function pulse({ reports = [], cohortSize = 120, minCases = 3, minCohort = 30, expertApproved = false, reviewerId = null } = {}) {
    const valid = assertArray(reports).filter(r => r.verifiedByExpert === true && r.model && r.userId), byModel = {};
    for (const r of valid) {
        const key = idText(r.model), set = byModel[key] || new Set();
        set.add(idText(r.userId));
        byModel[key] = set;
    }
    const cohort = number(cohortSize, 0, 1e7, 120), signals = Object.entries(byModel).map(([model, users]) => { const cases = users.size, qualified = cases >= minCases && cohort >= minCohort && cases <= cohort; return { model, distinctVerifiedCases: cases, cohortSize: cohort, observedRate: cohort ? money(cases / cohort * 100) : null, qualifiedForManualReview: qualified, mayNotifyExternally: qualified && expertApproved && typeof reviewerId === 'string' && reviewerId.length > 0 }; }).sort((a, b) => b.distinctVerifiedCases - a.distinctVerifiedCases);
    return outcome('PULSE', 'Verified independent incidents + review gate', { reportsCount: reports.length, cohortSize: cohort, minCases, minCohort, expertApproved, reviewerId: reviewerId || null }, { signals, notificationsSent: 0 }, 'An incident cluster is only a hypothesis. No customer notification is sent in the demo; a professional must authorize a real outreach.', ['Selection and reporting biases; population denominator not independently validated. This is not a product-recall or safety finding.']);
}
function economics({ basket = 300, margin = .2, service = 140, commission = .12, fulfillment = 35, acquisition = 15, support = 7, returns = 5, fixedCost = 3000 } = {}) {
    const b = number(basket, 0, 1e6, 300), m = number(margin, 0, 1, .2), s = number(service, 0, 1e6, 140), c = number(commission, 0, 1, .12);
    const costs = number(fulfillment, 0, 1e6, 35) + number(acquisition, 0, 1e6, 15) + number(support, 0, 1e6, 7) + number(returns, 0, 1e6, 5);
    const contribution = money(b * m + s * c - costs);
    return outcome('Economics', 'Auditable unit economics and break-even', { basket: b, margin: m, service: s, commission: c, fulfillment, acquisition, support, returns, fixedCost }, { grossProfit: money(b * m), commissionRevenue: money(s * c), variableCosts: money(costs), contribution, breakEvenOrders: contribution > 0 ? Math.ceil(number(fixedCost, 0, 1e9, 3000) / contribution) : null, profitablePerOrder: contribution > 0 }, 'Every number is an explicit editable assumption, not a financial metric supplied by OMA.', ['Excludes taxes, financing, capacity, refund tail risk and supplier contractual terms.']);
}
const RUNNERS = { zerobuy: zeroBuy, antifail: antiFail, domino, synccity: syncCity, proof, dna, forge, pulse, economics };

const OMA_FIXTURES = {"zerobuy":{"requirements":[{"id":"p02","name":"Cartridge","qty":1,"unitPrice":24},{"id":"p03","name":"FUM tape","qty":1,"unitPrice":6.9},{"id":"p04","name":"Hose","qty":2,"unitPrice":16}],"inventory":[{"id":"p03","qty":1},{"id":"p04","qty":1}]},"antifail":{"surface":"drywall","fastener":"concrete-anchor","loadKg":8,"verifiedWiring":false},"domino":{"order":["inspect","pipes","tiles","waterproof","finish"]},"synccity":{"selectedId":"r1","minGroup":3,"individualTripCost":24,"sharedTripCost":48,"requests":[{"id":"r1","city":"Минск","zone":"A","slot":"утро","service":"сантехник"},{"id":"r2","city":"Минск","zone":"A","slot":"утро","service":"сантехник"},{"id":"r3","city":"Минск","zone":"A","slot":"утро","service":"сантехник"},{"id":"r4","city":"Брест","zone":"A","slot":"утро","service":"сантехник"}]},"proof":{"projectId":"DEMO-102","steps":[{"code":"checked_materials","done":true},{"code":"inspection","done":true}],"photoHashes":["aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"],"inspector":null,"ownerConsent":false},"dna":{"homeType":"panel","room":"bath","area":4,"qtyPerM2":1.1,"templates":[{"id":"T-101","homeType":"panel","room":"bath","area":4,"inspection":"professional"},{"id":"T-102","homeType":"brick","room":"bath","area":5,"inspection":"self"},{"id":"T-103","homeType":"panel","room":"entry","area":3,"inspection":"professional"}]},"forge":{"interestThreshold":4,"assemblyCost":30,"minGrossMargin":0.15,"skuCosts":[{"id":"p18","cost":175},{"id":"p19","cost":25},{"id":"p20","cost":49}],"projects":[{"id":"a","problem":"entry-storage","homeType":"panel","optIn":true},{"id":"b","problem":"entry-storage","homeType":"panel","optIn":true},{"id":"c","problem":"entry-storage","homeType":"panel","optIn":true},{"id":"d","problem":"entry-storage","homeType":"panel","optIn":true},{"id":"e","problem":"entry-storage","homeType":"panel","optIn":false}]},"pulse":{"cohortSize":120,"minCases":3,"minCohort":30,"expertApproved":false,"reviewerId":null,"reports":[{"userId":"u1","model":"M-35","verifiedByExpert":true},{"userId":"u2","model":"M-35","verifiedByExpert":true},{"userId":"u3","model":"M-35","verifiedByExpert":true},{"userId":"u3","model":"M-35","verifiedByExpert":true},{"userId":"u4","model":"M-35","verifiedByExpert":false},{"userId":"u9","model":"T-12","verifiedByExpert":true}]},"economics":{"basket":300,"margin":0.2,"service":140,"commission":0.12,"fulfillment":35,"acquisition":15,"support":7,"returns":5,"fixedCost":3000}};
function omaRun(name, inputJSON) {
  const runner = RUNNERS[name];
  if (!runner) throw new Error('Unknown module: ' + name);
  const input = inputJSON ? JSON.parse(inputJSON) : OMA_FIXTURES[name];
  return JSON.stringify(runner(input));
}
