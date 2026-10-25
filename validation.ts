import {z} from 'zod';
import type {AppError} from './types.js';

// Runtime schemas are also the source of compile-time request types.

const id=z.string().trim().min(1).max(120).regex(/^[a-zA-Z0-9_-]+$/);
const text=(max: number,min=0)=>z.string().trim().min(min).max(max);
const positiveInt=(max=10_000)=>z.number().int().min(1).max(max);
const money=z.number().finite().min(0).max(10_000_000);
const empty=z.object({}).strict();

export const schemas={
 empty,
 demoLogin:z.object({userId:id}).strict(),
 createUser:z.object({name:text(60,1),city:text(40,1)}).strict(),
 patchUser:z.object({
  name:text(60,1).optional(),city:text(40,1).optional(),district:text(100).optional(),kind:text(100).optional(),homeType:text(100).optional(),
  address:text(100).optional(),area:z.number().finite().min(1).max(10_000).optional(),rooms:z.number().int().min(1).max(20).optional(),
  roomAreas:z.object({
   'Прихожая':z.number().finite().min(0).max(1_000).optional(),'Ванная':z.number().finite().min(0).max(1_000).optional(),
   'Комната':z.number().finite().min(0).max(1_000).optional(),'Балкон':z.number().finite().min(0).max(1_000).optional(),
   'Кухня':z.number().finite().min(0).max(1_000).optional(),'Сад':z.number().finite().min(0).max(1_000).optional()
  }).strict().optional()
 }).strict().refine(value=>Object.keys(value).length>0,{message:'Нет полей для изменения'}),
 inventoryCreate:z.object({productId:id.optional(),name:text(100,1).optional(),qty:positiveInt()}).strict().refine(value=>value.productId||value.name,{message:'Укажите товар или название'}),
 assistant:z.object({message:text(800,1),scenarioId:id.nullish()}).strict(),
 solve:z.object({
  task:text(500).default(''),scenarioId:id.optional(),budget:z.number().finite().min(50).max(150_000).optional(),
  area:z.number().finite().min(.5).max(120).optional(),mode:z.enum(['diy','hybrid','pro']).default('hybrid'),wrongMaterial:z.boolean().default(false),
  discountMode:z.boolean().optional(),stockCity:text(40,1).optional()
 }).strict(),
 sequence:z.object({calculationId:id,stepIds:z.array(id).min(1).max(30)}).strict().refine(value=>new Set(value.stepIds).size===value.stepIds.length,{message:'Этапы не должны повторяться'}),
 shelfEvaluate:z.object({
  projectId:id.optional(),surface:z.enum(['unknown','concrete','drywall','wood']).optional(),
  fastener:z.enum(['unknown','concrete-anchor','drywall-anchor','wood-screw']).optional(),
  shelfWeightKg:z.number().finite().min(0).max(1_000).optional(),plannedLoadKg:z.number().finite().min(0).max(1_000).optional(),
  wallInspected:z.boolean().optional(),verifiedWiring:z.boolean().optional(),manufacturerInstructionsChecked:z.boolean().optional(),
  products:z.array(z.object({id,name:text(100).optional(),unitPrice:money}).strict()).max(100).optional(),
  inventory:z.array(z.object({id,qty:z.number().finite().min(0).max(10_000)}).strict()).max(100).optional(),
  completedStepIds:z.array(id).max(6).optional(),photoHashes:z.array(z.string().regex(/^[a-f0-9]{64}$/)).max(10).optional()
 }).strict().refine(value=>!value.completedStepIds||new Set(value.completedStepIds).size===value.completedStepIds.length,{message:'Этапы не должны повторяться'}),
 calculationRef:z.object({calculationId:id}).strict(),
 reservationRef:z.object({reservationId:id}).strict(),
 projectComplete:z.object({
  checklist:z.array(z.boolean()).min(1).max(20),note:text(900).default(''),
  image:z.string().max(1_700_000).regex(/^data:image\/(png|jpeg|webp);base64,/).nullable().optional()
 }).strict(),
 cartItem:z.object({productId:id,quantity:positiveInt(200)}).strict(),
 groupCreate:z.object({title:text(100,1),category:text(80,1),target:positiveInt(100).min(2),basePrice:money.max(50_000),description:text(250).optional(),date:text(20).optional()}).strict(),
 pulseReport:z.object({category:text(80).default('Другое'),model:text(80).default(''),symptom:text(450,8)}).strict(),
 dnaMatch:z.object({room:text(80),area:z.number().finite().min(.5).max(1_000)}).strict(),
 metrics:z.object({aov:money.optional(),margin:z.number().finite().min(0).max(100).optional(),avgService:money.optional(),commission:z.number().finite().min(0).max(100).optional(),cost:money.optional()}).strict(),
 analytics:z.object({
  name:z.enum(['page_view','task_started','calculation_completed','project_saved','cart_imported','reservation_created','order_created','proof_completed','error_shown','offline_changed']),
  properties:z.object({view:id.optional(),scenarioId:id.optional(),code:text(80).optional(),online:z.boolean().optional()}).strict().default({})
 }).strict()
};

export function parse<Schema extends z.ZodType>(schema: Schema,input: unknown): z.output<Schema>{
 const result=schema.safeParse(input);
 if(result.success)return result.data;
 const error: AppError=new Error('Запрос не прошёл валидацию');
 error.status=422;
 error.code='VALIDATION_ERROR';
 error.details=result.error.issues.map(issue=>({path:issue.path.join('.'),message:issue.message}));
 throw error;
}
