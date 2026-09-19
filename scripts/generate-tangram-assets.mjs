#!/usr/bin/env node
// Original, deterministic vector artwork and small synthesized wooden/chime sounds.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
const root = new URL('../entry/src/main/resources/rawfile/gamesNext/tangramGarden/', import.meta.url);
const levelsSrc = ['TangramGeometry','TangramLevels'].map(n => readFileSync(new URL(`../entry/src/main/ets/gamesNext/tangramGarden/${n}.ets`,import.meta.url),'utf8')).join('\n').replace(/^import[\s\S]*?;\n/gm,'').replace(/^export /gm,'');
const {TANGRAM_LEVELS: levels,tangramPolygon: polygon,tangramBounds: bounds} = vm.runInNewContext(stripTypeScriptTypes(levelsSrc)+`;({TANGRAM_LEVELS,tangramPolygon,tangramBounds})`);
const colors = ['#EDB569','#ED9684','#A8C78E','#93C7D2','#C5A6D4','#F3D17C','#A5BCE2'];
function save(path,body){let u=new URL(path,root);mkdirSync(new URL('.',u),{recursive:true});writeFileSync(u,body);}
function svg(body,size=256){return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 256 256">${body}</svg>\n`;}
function figure(id,face=true){let l=levels.find(l=>l.id===id),ps=l.poses.map(polygon),b=bounds(ps),s=Math.min(182/b.width,174/b.height),x=128-(b.x+b.width/2)*s,y=124-(b.y+b.height/2)*s;return `<g transform="translate(${x.toFixed(4)} ${y.toFixed(4)}) scale(${s.toFixed(4)})">`+ps.map((p,i)=>{let cx=p.reduce((s,v)=>s+v.x,0)/p.length,cy=p.reduce((s,v)=>s+v.y,0)/p.length;return `<polygon points="${p.map(v=>`${v.x.toFixed(5)},${v.y.toFixed(5)}`).join(' ')}" fill="${colors[i]}" stroke="#695839" stroke-opacity=".28" stroke-width=".03" stroke-linejoin="round"/>`+(face?`<g fill="#514D3E"><circle cx="${cx-.085}" cy="${cy-.015}" r=".023"/><circle cx="${cx+.085}" cy="${cy-.015}" r=".023"/></g><path d="M${cx-.035} ${cy+.05}q.035 .04 .07 0" fill="none" stroke="#514D3E" stroke-width=".018" stroke-linecap="round"/>`:'');}).join('')+'</g>';}
for(const l of levels)save(`levels/${l.id}.svg`,svg(figure(l.id)));
for(let id=0;id<7;id++){
 const p=polygon({id,x:0,y:0,turn:0,flip:false}),b=bounds([p]),scale=170/Math.max(b.width,b.height);
 const pts=p.map(v=>`${((v.x-b.x-b.width/2)*scale+128).toFixed(4)},${((v.y-b.y-b.height/2)*scale+128).toFixed(4)}`).join(' ');
 save(`pieces/${id}.svg`,svg(`<polygon points="${pts}" fill="${colors[id]}" stroke="#716047" stroke-width="4" stroke-linejoin="round"/>`));
}
save('scene/guide.svg',`<svg xmlns="http://www.w3.org/2000/svg" width="400" height="130" viewBox="0 0 400 130"><rect x="4" y="4" width="392" height="122" rx="25" fill="#ECEDD9"/><path d="M32 28h60v60z" fill="#EDB569" stroke="#D6A05B" stroke-width="2"/><circle cx="74" cy="46" r="2" fill="#62513B"/><circle cx="83" cy="46" r="2" fill="#62513B"/><path d="M105 65h45m-9-9 9 9-9 9" fill="none" stroke="#719460" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M176 96V36h60v60zM176 36l60 60" fill="#DDE5C9" stroke="#96AE7B" stroke-width="2" stroke-dasharray="5 5"/><path d="M176 36h60v60z" fill="#EDB569"/><path d="m176 36 60 60h-60z" fill="#ED9684"/><circle cx="215" cy="49" r="2" fill="#62513B"/><circle cx="224" cy="49" r="2" fill="#62513B"/><path d="m310 62 13 13 28-31" fill="none" stroke="#719460" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/><path d="m345 25 3 8 8 2-8 3-3 8-3-8-8-3 8-2z" fill="#D6B161"/></svg>`);

const sprig='<path d="M45 216v-40" fill="none" stroke="#81A274" stroke-width="5" stroke-linecap="round"/><path d="M44 198q-30 0-29-23 28 1 29 23M46 190q0-24 25-25-1 22-25 25" fill="#A3BE8C"/>';
const paper='<rect x="8" y="8" width="240" height="240" rx="68" fill="#FFF0D1"/><circle cx="197" cy="59" r="18" fill="#F4D88C"/><path d="M51 222h151" stroke="#D7B786" stroke-width="8" stroke-linecap="round"/>';
save('scene/logo.svg',svg(paper+figure('home')+sprig));
for(const dark of [false,true]){
 const k=dark?'dark':'light',leaf=dark?'#40523B':'#DCE8CA',wood=dark?'#665840':'#EDD1A4',light=dark?'#56654C':'#EBDCB7';
 save(`scene/branches_${k}.svg`,`<svg xmlns="http://www.w3.org/2000/svg" width="260" height="360" viewBox="0 0 260 360"><path d="M242 347Q185 235 238 88" fill="none" stroke="${wood}" stroke-width="3"/><path d="M222 271q-75-8-69-59 60 6 69 59m-1-41q6-65 37-64-1 54-37 64m4-49q-45-14-39-46 39 5 39 46m8-47q0-35 26-44-1 31-26 44" fill="${leaf}"/><circle cx="89" cy="294" r="5" fill="none" stroke="${light}" stroke-width="2"/><path d="m60 183 12-14 9 17z" fill="${wood}" opacity=".5"/><circle cx="195" cy="64" r="3" fill="${leaf}"/></svg>`);
}
const paths={back:'M19 12H5m7-7-7 7 7 7',sound:'M4 9h4l5-4v14l-5-4H4zM16 8q5 4 0 8m3-11q8 7 0 14',muted:'M4 9h4l5-4v14l-5-4H4zM17 9l5 6m0-6-5 6',help:'M9 8a3 3 0 1 1 5 2c-2 1-2 2-2 3m0 4v.1M22 12A10 10 0 1 1 2 12a10 10 0 1 1 20 0',album:'M4 4h16v16H4zM8 4v16M11 9l3-3 3 3m-6 6h6',undo:'M5 5v6h6M5 11a8 8 0 1 1 2 8','rotate-left':'M4 4v6h6M4 10a8 8 0 1 1 2 9','rotate-right':'M20 4v6h-6m6 0a8 8 0 1 0-2 9',flip:'M12 3v18M8 6 3 18h5V6m8 0 5 12h-5V6',hint:'M9 19h6m-5 3h4M8 14a6 6 0 1 1 8 0c-1 1-1 2-1 3H9c0-1 0-2-1-3',guide:'M4 4h16v16H4zm0 0 16 16M12 4v8H4',reset:'M20 5v6h-6m6-1a8 8 0 1 0-1 9',check:'m5 12 4 4L20 5',next:'M5 12h14m-6-6 6 6-6 6',up:'M12 20V4m-6 6 6-6 6 6',down:'M12 4v16m-6-6 6 6 6-6',left:'M20 12H4m6-6-6 6 6 6',right:'M4 12h16m-6-6 6 6-6 6',close:'m6 6 12 12M6 18 18 6',tray:'M4 9v11h16V9M8 14l4 3 4-3m-4-9v12'};
for(const [name,path]of Object.entries(paths))for(const [mode,color]of Object.entries({light:'#514B3B',dark:'#F6EDDC',on:'#FFF9EA'}))save(`icons/${name}_${mode}.svg`,`<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="${path}" fill="none" stroke="${color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>\n`);
const badgeBase='<path d="m62 173-6 70 40-22 30 18 10-61m1 0 12 61 28-18 34 22-12-70" fill="#94B88E"/><circle cx="128" cy="116" r="100" fill="#F9E7BC" stroke="#CAA36A" stroke-width="5"/><circle cx="128" cy="116" r="87" fill="#FFFAE9" stroke="#E6C992" stroke-width="2"/>';
const badgePath=new URL('../../../app/achievements/',new URL('scene/',root));
mkdirSync(badgePath,{recursive:true});
let first=`${badgeBase}<g transform="translate(26 10) scale(.8)">${figure('home')}${sprig}</g><path d="m198 38 4 10 11 3-11 4-4 11-4-11-11-4 11-3z" fill="#D9A956"/>`;
let three=`${badgeBase}<g transform="translate(40 56) rotate(-12 55 60)"><rect width="80" height="116" rx="12" fill="#E4B077" stroke="#B18B59" stroke-width="2"/></g><g transform="translate(140 48) rotate(12 30 70)"><rect width="77" height="116" rx="12" fill="#A8C1D5" stroke="#71919F" stroke-width="2"/></g><rect x="80" y="62" width="98" height="122" rx="14" fill="#FFF9E7" stroke="#D1B177" stroke-width="3"/><g transform="translate(84 83) scale(.36)">${figure('boat')}</g><path d="m112 165 9 8 18-20" fill="none" stroke="#66915E" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>`;
let album=`${badgeBase}<rect x="64" y="52" width="134" height="137" rx="16" fill="#A9C494" stroke="#6F935F" stroke-width="3"/><path d="M84 54v133" stroke="#739467" stroke-width="4"/><rect x="100" y="71" width="79" height="85" rx="12" fill="#FFFAE8"/><g transform="translate(96 68) scale(.35)">${figure('cat')}</g><path d="m132 179 4-9 9-1-7-6 2-10-8 5-9-5 2 10-7 6 10 1z" fill="#F8DE94"/>`;
for(const [name,body]of Object.entries({first,three,album}))writeFileSync(new URL(`ach_tangram_${name}.svg`,badgePath),svg(body));
// 24kHz mono PCM. Soft attack/release; no downloaded audio or dependency.
for(const [name,notes]of Object.entries({pick:[640],turn:[520,660],snap:[780,980],hint:[640,850,1080],win:[523.25,659.25,783.99,1046.5],tap:[440]})){
 const rate=24000,step=name==='win'?.115:.065,duration=notes.length*step+.15,count=Math.ceil(rate*duration),buf=Buffer.alloc(44+count*2);
 buf.write('RIFF');buf.writeUInt32LE(buf.length-8,4);buf.write('WAVEfmt ',8);buf.writeUInt32LE(16,16);buf.writeUInt16LE(1,20);buf.writeUInt16LE(1,22);buf.writeUInt32LE(rate,24);buf.writeUInt32LE(rate*2,28);buf.writeUInt16LE(2,32);buf.writeUInt16LE(16,34);buf.write('data',36);buf.writeUInt32LE(count*2,40);
 for(let i=0;i<count;i++){let t=i/rate,v=0;notes.forEach((freq,n)=>{let u=t-n*step;if(u<0)return;const envelope=Math.min(1,u/.008)*Math.exp(-u*19)*Math.min(1,(duration-t)/.025);v+=(Math.sin(2*Math.PI*freq*u)+.2*Math.sin(2*Math.PI*freq*2.01*u))*envelope*.22;});buf.writeInt16LE(Math.round(Math.max(-1,Math.min(1,v))*32767),44+i*2);}
 save(`audio/${name}.wav`,buf);
}
console.log(`Tangram: ${levels.length} puzzle SVGs, scene, icons, 3 badges, 6 sounds generated.`);
