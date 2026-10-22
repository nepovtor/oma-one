// Deliberately synthetic fixtures. No real addresses, consumers, suppliers, prices or safety incidents.
export const FIXTURES={
 zerobuy:{requirements:[{id:'p02',name:'Cartridge',qty:1,unitPrice:24},{id:'p03',name:'FUM tape',qty:1,unitPrice:6.9},{id:'p04',name:'Hose',qty:2,unitPrice:16}],inventory:[{id:'p03',qty:1},{id:'p04',qty:1}]},
 antifail:{surface:'drywall',fastener:'concrete-anchor',loadKg:8,verifiedWiring:false},
 domino:{order:['inspect','pipes','tiles','waterproof','finish']},
 synccity:{selectedId:'r1',minGroup:3,individualTripCost:24,sharedTripCost:48,requests:[{id:'r1',city:'Минск',zone:'A',slot:'утро',service:'сантехник'},{id:'r2',city:'Минск',zone:'A',slot:'утро',service:'сантехник'},{id:'r3',city:'Минск',zone:'A',slot:'утро',service:'сантехник'},{id:'r4',city:'Брест',zone:'A',slot:'утро',service:'сантехник'}]},
 proof:{projectId:'DEMO-102',steps:[{code:'checked_materials',done:true},{code:'inspection',done:true}],photoHashes:['a'.repeat(64)],inspector:null,ownerConsent:false},
 dna:{homeType:'panel',room:'bath',area:4,qtyPerM2:1.1,templates:[{id:'T-101',homeType:'panel',room:'bath',area:4,inspection:'professional'},{id:'T-102',homeType:'brick',room:'bath',area:5,inspection:'self'},{id:'T-103',homeType:'panel',room:'entry',area:3,inspection:'professional'}]},
 forge:{interestThreshold:4,assemblyCost:30,minGrossMargin:.15,skuCosts:[{id:'p18',cost:175},{id:'p19',cost:25},{id:'p20',cost:49}],projects:[{id:'a',problem:'entry-storage',homeType:'panel',optIn:true},{id:'b',problem:'entry-storage',homeType:'panel',optIn:true},{id:'c',problem:'entry-storage',homeType:'panel',optIn:true},{id:'d',problem:'entry-storage',homeType:'panel',optIn:true},{id:'e',problem:'entry-storage',homeType:'panel',optIn:false}]},
 pulse:{cohortSize:120,minCases:3,minCohort:30,expertApproved:false,reviewerId:null,reports:[{userId:'u1',model:'M-35',verifiedByExpert:true},{userId:'u2',model:'M-35',verifiedByExpert:true},{userId:'u3',model:'M-35',verifiedByExpert:true},{userId:'u3',model:'M-35',verifiedByExpert:true},{userId:'u4',model:'M-35',verifiedByExpert:false},{userId:'u9',model:'T-12',verifiedByExpert:true}]},
 economics:{basket:300,margin:.2,service:140,commission:.12,fulfillment:35,acquisition:15,support:7,returns:5,fixedCost:3000}
};
