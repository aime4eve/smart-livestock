const { chromium } = require('playwright');
const TOKEN='eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIyIiwidGlkIjoxLCJyb2xlIjoiT1dORVIiLCJpYXQiOjE3OTAzMTQ1NTYsImV4cCI6MTc5MDMxODE1Nn0.Bj9yhs-MUNRhktTNY3kuPZk_BonuzEv9D733ojD09EqKtJQRk88M63J_PE4Uayd0sl8LCT6Xb9-p83UgunUQHA';
const USER={"id":2,"name":"Rancher Zhang","phone":"13800138000","role":"OWNER","tenantId":1,"active":true,"mustChangePassword":false};
const BASE='http://172.22.1.123:19080';
(async()=>{
 const b=await chromium.launch({headless:true});
 const p=await b.newPage({viewport:{width:400,height:850},deviceScaleFactor:2});
 await p.addInitScript(([t,u])=>{
   localStorage.setItem('flutter.access_token',t);
   localStorage.setItem('flutter.user_info',u);
   localStorage.setItem('flutter.active_farm_id','1');
 },[TOKEN,JSON.stringify(USER)]);
 await p.goto(BASE+'/ranch',{waitUntil:'networkidle',timeout:60000});
 await p.waitForTimeout(18000);
 await p.screenshot({path:'/tmp/fence-walk-list.png'});
 await p.mouse.click(200,491);
 await p.waitForTimeout(6000);
 await p.screenshot({path:'/tmp/fence-walk-list-tab.png'});
 await p.mouse.click(200,565);
 await p.waitForTimeout(3000);
 await p.screenshot({path:'/tmp/fence-walk-selected.png'});
 await p.mouse.move(200,700);
 await p.mouse.wheel(0,1200);
 await p.waitForTimeout(2000);
 await p.screenshot({path:'/tmp/fence-walk-scrolled.png'});
 console.log('done '+p.url());
 await b.close();
})().catch(e=>{console.error(e);process.exit(1);});
