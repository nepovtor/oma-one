/* OMA VIBE. Conceptual editorial UI over the same demo catalog and cart. */
import type {Dynamic} from './state.js';
export type VibeStage = 'home' | 'styles' | 'studio' | 'materials' | 'projects' | 'profile';
const escapes: Record<string,string> = {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'};
const e = (v: unknown):string => String(v ?? '').replace(/[&<>"']/g,ch=>escapes[ch] || ch);
const rub = (n: number) => new Intl.NumberFormat('ru-RU',{maximumFractionDigits:2}).format(n)+' BYN';
const stageButton=(text:string,stage:VibeStage,cls='vibe-button') => '<button type="button" class="'+cls+'" data-action="vibe-stage" data-id="'+stage+'">'+e(text)+'</button>';
const src=(name:string)=>'/vibe/'+name+'.jpg';
const photo=(file:string,label:string,cls='vibe-photo')=>'<img class="'+cls+'" src="'+src(file)+'" alt="'+e(label)+'" loading="lazy">';
const flag='<span class="vibe-caveat">Синтетический интерьерный референс · не скан комнаты</span>';
function nav(stage:string):string {
 const entries:[VibeStage,string,string][]=[['home','✦','VIBE'],['styles','◈','Стили'],['studio','▣','Комната'],['materials','▤','Материалы'],['profile','◯','Профиль']];
 return '<nav class="vibe-tabs" aria-label="Навигация OMA VIBE">'+entries.map(([id,mark,label])=>'<button data-action="vibe-stage" data-id="'+id+'" class="'+(id===stage?'active':'')+'" '+(id===stage?'aria-current="page"':'')+'><span aria-hidden="true">'+mark+'</span>'+label+'</button>').join('')+'</nav>';
}
function profile(products:Dynamic[],cartCount:number,saved:boolean):string {
 return '<header class="vibe-page-head"><span class="vibe-kicker">МОЙ VIBE</span><h1>Мой профиль</h1><p>Один профиль и общая корзина с обычным ОМА.</p></header>'+
 '<div class="vibe-white-card"><strong>В общей корзине</strong><p>'+cartCount+' товаров · данные демонстрационные</p><button data-view="cart" class="vibe-button">Открыть общую корзину</button></div>'+
 '<div class="vibe-white-card"><strong>Проект «Моя спальня»</strong><p>'+(saved?'Локальный VIBE-черновик сохранён':'Черновик ещё не сохранён')+'</p>'+stageButton('Открыть проект','studio','vibe-outline')+'</div>'+
 '<button data-view="home" class="vibe-outline vibe-wide">Вернуться в обычный ОМА</button>';
}
export function renderVibe(stage:VibeStage,style:string,owned:boolean,products:Dynamic[],cartCount:number,saved:boolean):string {
 const selected=products.filter((p:Dynamic)=>['p18','p20'].includes(p.id));
 const subtotal=selected.reduce((sum:number,p:Dynamic)=>sum+(owned&&p.id==='p20'?0:Number(p.price||0)),0);
 const tabs=nav(stage);
 const top='<div class="vibe-top"><div class="vibe-wordmark"><span>ОМА</span><strong>VIBE</strong></div><button type="button" data-view="home" class="vibe-exit" aria-label="Вернуться в обычный ОМА">← Обычный ОМА</button></div>';
 const footer='<p class="vibe-legal">Неофициальный концепт. Интерьеры, цены и остатки синтетические; реальные интеграции не подключены.</p>';
 let body='';
 if(stage==='home'){
  body='<div class="vibe-home-heading"><span class="vibe-kicker">ТВОЁ ПРОСТРАНСТВО, ТВОИ ПРАВИЛА</span><h1>Твой дом.<br>Твой <em>вайб.</em></h1><p>Вдохновляйся. Планируй. Воплощай.</p></div>'+
   '<section class="vibe-hero" aria-label="Стиль Soft Loft">'+photo('bedroom','Фотореалистичный синтетический интерьер спальни в стиле Soft Loft','vibe-hero-image')+
   '<div class="vibe-hero-shade"><span>SOFT LOFT · СПАЛЬНЯ</span><h2>Первый дом.<br>Свой характер.</h2>'+stageButton('Преобразить комнату ✨','studio','vibe-button vibe-coral')+'</div></section>'+
   '<div class="vibe-section-title"><h2>Идеи для тебя</h2><button type="button" data-action="vibe-stage" data-id="styles">Все стили →</button></div>'+
   '<div class="vibe-tiles"><button data-action="vibe-stage" data-id="styles" class="vibe-inspo">'+photo('living','Синтетический референс гостиной')+'<strong>Выбрать стиль</strong><small>От Soft Loft до Japandi</small></button>'+
   '<button data-action="vibe-stage" data-id="materials" class="vibe-inspo">'+photo('bedroom','Синтетический референс спальни')+'<strong>До своего бюджета</strong><small>Товары из демо-каталога</small></button></div>';
 }else if(stage==='styles'){
  body='<header class="vibe-page-head"><span class="vibe-kicker">ОТ ИДЕИ К РЕЗУЛЬТАТУ</span><h1>Какой интерьер — твой?</h1><p>Выбери настроение. Рендеры ниже — концептуальные, не персональная AI-визуализация.</p></header>'+
   '<div class="vibe-styles">'+['Soft Loft','Japandi','Cozy Minimal','Scandinavian'].map((name,i)=>'<button type="button" data-action="vibe-style" data-id="'+e(name)+'" class="vibe-style '+(name===style?'chosen':'')+'">'+photo(i===0?'bedroom':'living','Синтетический интерьер, стиль '+name)+'<span><strong>'+name+'</strong><small>'+(name===style?'Выбрано':'Выбрать стиль')+'</small></span><b aria-hidden="true">'+(name===style?'✓':'○')+'</b></button>').join('')+'</div>'+stageButton('Продолжить →','studio','vibe-button vibe-wide');
 }else if(stage==='studio'){
  body='<header class="vibe-page-head"><span class="vibe-kicker">МОЯ КОМНАТА · 13 М²</span><h1>Идея для твоей спальни</h1><p>Съёмная квартира · '+e(style)+' · бюджет 1 200 BYN</p></header>'+
   '<div class="vibe-studio-image">'+photo('bedroom','Синтетический целевой интерьер, визуальный пример для проекта')+'<span class="vibe-studio-tag">РЕФЕРЕНС · '+e(style)+'</span></div>'+flag+
   '<div class="vibe-white-card"><strong>Что можно изменить без ремонта?</strong><p>Текстиль, свободностоящая мебель и декор. Сверление и изменение конструкций не включены.</p><label class="vibe-switch"><input type="checkbox" id="vibe-no-drill" checked disabled>Без сверления</label></div>'+
   stageButton('Посмотреть материалы →','materials','vibe-button vibe-wide')+
   '<p class="vibe-minor">До/После с реальным фото пользователя — будущий этап, здесь не имитируется работающая AI-функция.</p>';
 }else if(stage==='materials'){
  body='<header class="vibe-page-head"><span class="vibe-kicker">ИЗ ИДЕИ В ДЕЙСТВИЕ</span><h1>Сделать это у себя</h1><p>Доступные варианты из текущего демо-каталога, не полная комплектация интерьера.</p></header>'+
   '<div class="vibe-total"><div><small>ПРЕДВАРИТЕЛЬНЫЙ СПИСОК</small><strong>'+rub(subtotal)+'</strong></div><span>Демо</span></div>'+
   '<label class="vibe-owned"><input type="checkbox" id="vibe-owned" '+(owned?'checked':'')+'><span><strong>Обувница уже есть?</strong><small>ZeroBuy не учитывает её в покупке</small></span></label>'+
   '<div class="vibe-materials">'+selected.map((p:Dynamic)=>'<article class="vibe-product">'+
   '<img src="/products/ProductP'+String(p.id).replace(/\D/g,'').padStart(2,'0')+'.jpg" alt="'+e(p.name)+'" loading="lazy">'+
   '<div><strong>'+e(p.name)+'</strong><small>'+rub(Number(p.price||0))+'</small><button type="button" data-action="add-cart" data-id="'+e(p.id)+'" '+(owned&&p.id==='p20'?'disabled':'')+'>Добавить в общую корзину</button></div></article>').join('')+'</div>'+
   '<div class="vibe-note">✓ Для съёмной квартиры: этот пример не содержит операций со сверлением. Совместимость настоящих материалов требует проверки.</div>'+
   '<button data-view="cart" class="vibe-button vibe-wide">Открыть общую корзину · '+cartCount+'</button>'+
   '<button type="button" data-action="vibe-save" class="vibe-outline vibe-wide">Сохранить VIBE-черновик на устройстве</button>';
 }else if(stage==='projects'){
  body='<header class="vibe-page-head"><span class="vibe-kicker">МОЙ ДОМ</span><h1>Моя спальня</h1><p>'+e(style)+' · личная история преображения</p></header>'+
    '<section class="vibe-studio-image">'+photo('overview','Синтетический референс плана квартиры')+'</section>'+flag+
    '<div class="vibe-white-card"><strong>'+(saved?'Черновик сохранён локально':'Черновик не сохранён')+'</strong><p>Отметки о завершении работ пользователь должен подтверждать отдельно.</p></div>'+
    stageButton('Продолжить проект','studio','vibe-button vibe-wide')+
    '<button data-view="projects" class="vibe-outline vibe-wide">Общий раздел проектов ОМА</button>';
 }else{body=profile(products,cartCount,saved);}
 return '<section class="oma-vibe" aria-label="ОМА VIBE">'+top+'<div class="vibe-body">'+body+footer+'</div>'+tabs+'</section>';
}
