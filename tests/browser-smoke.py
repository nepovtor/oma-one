"""Optional browser smoke check; requires Playwright Python + Chromium.
The execution environment blocks http browser navigation, so static documents and
API calls are bridged into the browser while preserving real application JS.
"""
from playwright.sync_api import sync_playwright
from pathlib import Path
import requests
import os

root=Path(__file__).resolve().parents[1]
html=(root/'public/index.html').read_text().replace('<script type="module" src="/app.js"></script>','').replace('<link rel="stylesheet" href="/styles.css">','')
css=(root/'public/styles.css').read_text();css=css[css.find(':root'):]
api_js=(root/'public/api.js').read_text().replace('export async function','async function')
state_js=(root/'public/state.js').read_text().replace('export const S','const S')
app_js='\n'.join(line for line in (root/'public/app.js').read_text().splitlines() if not line.startswith('import '))
js='\n'.join([api_js,state_js,app_js])

def test_page(page):
  session=requests.Session()
  def proxy(u,method='GET',data='',headers=None):
    if not u:return {'status':400,'body':'{"error":"invalid url"}'}
    outgoing={'Content-Type':'application/json'}
    if headers and headers.get('x-csrf-token'):outgoing['X-CSRF-Token']=headers['x-csrf-token']
    r=session.request(method,'http://127.0.0.1:8787'+u,data=data,headers=outgoing,timeout=10)
    return {'status':r.status_code,'body':r.text,'csrf':session.cookies.get('oma_csrf') or ''}
  page.expose_function('fetchProxy',proxy)
  page.set_content(html)
  page.add_style_tag(content=css)
  page.evaluate('''Object.defineProperty(window,'localStorage',{configurable:true,value:{getItem(k){return null},setItem(k,v){}}});let browserCookies='';Object.defineProperty(document,'cookie',{configurable:true,get(){return browserCookies},set(value){browserCookies=value.split(';',1)[0]}});window.fetch = async function(url,options={}) {const headers=Object.fromEntries(new Headers(options.headers||{}));const r=await window.fetchProxy(url,options.method||'GET',options.body||'',headers);if(r.csrf)browserCookies='oma_csrf='+encodeURIComponent(r.csrf);return new Response(r.body,{status:r.status,headers:{'Content-Type':'application/json'}})};''')
  page.add_script_tag(content=js)
  page.locator('.task-card').first.wait_for(timeout=10000)
  return page

with sync_playwright() as p:
  executable=os.getenv('PLAYWRIGHT_CHROMIUM_EXECUTABLE')
  browser=p.chromium.launch(headless=True,executable_path=executable or None,args=['--no-sandbox'])
  page=browser.new_page(viewport={'width':1440,'height':900})
  logs=[]
  page.on('pageerror',lambda e:logs.append('pageerror:'+str(e)))
  test_page(page)
  assert page.locator('.nav-item').count()==15
  page.locator('button[data-action="choose-scenario"][data-id="shelf"]').click()
  assert page.locator('#plan-form').count()==1
  page.locator('#task-budget').fill('230')
  page.locator('#task-risk').check()
  page.locator('#plan-form button[type=submit]').click()
  page.wait_for_timeout(400)
  assert page.get_by_text('Результаты проверки').count()>0
  assert page.get_by_text('Неверный крепёж для основания').count()>0
  page.locator('button[data-action="add-plan-cart"]').click()
  page.wait_for_timeout(300)
  assert page.get_by_text('Ваш заказ').count()>0
  page.locator('button[data-action="checkout"]').click()
  page.wait_for_timeout(300)
  assert page.get_by_text('История демо-заказов').count()>0
  page.locator('button[data-view="zerobuy"]').first.click()
  assert page.get_by_text('Мои материалы и инструменты').count()>0
  page.locator('#inv-product').select_option('p07')
  page.locator('#inventory-form button[type=submit]').click()
  page.wait_for_timeout(200)
  page.locator('button[data-view="forge"]').first.click()
  page.locator('button[data-action="vote-forge"]').first.click()
  page.wait_for_timeout(200)
  assert page.get_by_text('Ваш голос учтён').count()>0
  page.locator('button[data-view="pulse"]').first.click()
  page.locator('#pulse-symptom').fill('Обнаружена небольшая протечка под мойкой.')
  page.locator('#pulse-form button[type=submit]').click()
  page.wait_for_timeout(200)
  assert page.get_by_text('Мои сообщения').count()>0
  page.locator('button[data-view="dna"]').first.click()
  page.locator('button[data-action="dna-use"]').first.click()
  page.wait_for_timeout(400)
  assert page.locator('#plan-form').count()==1
  page.locator('button[data-action="save-plan"]').click()
  page.wait_for_timeout(300)
  page.locator('button[data-view="proof"]').first.click()
  assert page.locator('#proof-form').count()==1
  for item in page.locator('input[name="proof-check"]').all(): item.check()
  page.locator('#proof-note').fill('Работа завершена и осмотрена.')
  page.locator('#proof-form button[type=submit]').click()
  page.wait_for_timeout(300)
  assert page.get_by_text('Отмечено выполненным').count()==0  # Proof history marks it as completed, not projects card
  page.locator('button[data-view="synccity"]').first.click()
  page.locator('button[data-action="join-group"]').first.click()
  page.wait_for_timeout(200)
  assert page.get_by_text('Вы участвуете').count()>0
  page.screenshot(path=str(root/'test-output'/'desktop-final.png'),full_page=True)
  print('DESKTOP: basic flows passed, JS errors:', logs)
  assert not logs

  mobile=browser.new_page(viewport={'width':390,'height':844},device_scale_factor=1)
  test_page(mobile)
  assert mobile.locator('.mobile-tabs').is_visible()
  mobile.screenshot(path=str(root/'test-output'/'mobile.png'),full_page=True)
  print('MOBILE: responsive layout loaded')
  browser.close()
