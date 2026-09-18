import { ArenaConfig, ArenaScenario, ArenaRound, ARENA_MISSIONS, ARENA_SKILLS, arenaScenario } from './ArenaModel';

export interface ArenaEventGuide {
  id: string; name: string; icon: string; when: string; effect: string; tip: string;
}
export const ARENA_EVENTS: ArenaEventGuide[] = [
  {id:'none',name:'平静庭院',icon:'leaf',when:'全程无额外事件',
    effect:'没有花盆、风场、换队或收圈。小队按通常的相遇规则交锋。',tip:'第一次玩可以从这里开始，先熟悉三方克制和所选模式。'},
  {id:'garden',name:'花盆迷阵',icon:'leaf',when:'从开局到结束',
    effect:'场内有三盆固定的植物。队员无法穿过花盆，会绕路追逐，双方都受影响。',tip:'集结时尽量选择花盆之间的空地，留意被花盆分开的队友。'},
  {id:'wind',name:'一阵微风',icon:'wind',when:'第 18 秒预告 · 第 20–25 秒生效',
    effect:'虚线圈标出的风场会将圈内所有队员向外推，包括我方。每局只出现一次；风本身不会直接让队员换队。',tip:'看到虚线圈后，避开风口或提前护住队友；它可能打散正在占点的小队。'},
  {id:'traitor',name:'临阵换队',icon:'tune',when:'第 20 秒标记 · 第 23 秒换队',
    effect:'随机选中场上一位队员，头顶倒计时 3 秒后换队。按当时的身份从石头→剪刀→布→石头变化，每局一次。任何一队都可能被选中。',
    tip:'留意倒计时，让附近队友做好调整。护盾只挡碰撞转阵，不能阻止这次事件。'},
  {id:'shrink',name:'围栏收拢',icon:'expand',when:'第 12 秒预告 · 第 15 秒开始',
    effect:'围栏逐渐向内收拢，到上限后停止。可活动空间变小，队员更容易相遇。',tip:'提前把小队向内集结，给关键队员留出回旋空间。'}
];
export function arenaEventGuide(id: string): ArenaEventGuide {
  return ARENA_EVENTS.find((event:ArenaEventGuide):boolean => event.id===id) ?? ARENA_EVENTS[0];
}
export function arenaScenarioEvents(s: ArenaScenario): ArenaEventGuide[] {
  return ARENA_EVENTS.filter((event:ArenaEventGuide):boolean =>
    (event.id==='garden' && s.obstacles) || (event.id==='wind' && s.wind) ||
    (event.id==='traitor' && s.traitor) || (event.id==='shrink' && s.shrink));
}
export function arenaWinGuide(s: ArenaScenario): string {
  if(s.rule==='survival')return `撑到 ${s.limit} 秒时，我方至少还剩 1 位队员就获胜；中途我方归零则立即失败。`;
  if(s.rule==='zones')return `先拿到 ${s.target} 据点分就获胜；${s.limit} 秒到时，也可凭最高分获胜。最高分并列则平局。`;
  return `场上只剩我方时立即获胜；${s.limit} 秒到时，我方队员数量最多也算获胜。最高数量并列则平局。`;
}
export function arenaMissionSkills(i: number): string {
  const skills=ARENA_MISSIONS[i].skills;
  return ARENA_SKILLS.filter((name:string,index:number):boolean => skills[index]).join(' / ');
}
export function arenaMissionStars(i: number): string[] {
  const s=ARENA_MISSIONS[i];
  return ['完成本关目标，获得 1 星。',
    s.skills[2] ? '风推使用不超过 1 次，通关时额外得 1 星。' : '本关没有风推，通关时自动额外得 1 星。',
    s.rule==='survival' ? '获胜时至少剩 3 位队员，再得 1 星。' : `在 ${s.limit*.8} 秒内获胜，再得 1 星。`];
}
export const ARENA_MISSION_TIPS: string[] = [
  '只有集结可用。点集结，再按住战场选择位置、松手释放。让更多队友进入中心圆圈，并保持人数领先。',
  '我方 6 位，对方各 9 位。先护住聚在一起的队友，再用集结抢点；留一次风推用于解围。',
  '这关没有据点，也没有援军。护阵可以挡一次碰撞转阵，风推可以解围；保住队友比追着对手跑更重要。',
  '花盆会挡路。选花盆之间的空地集结，尽量让队友一起进入据点。',
  '风场只出现一次。第 18 秒看到预告后，留意圈内队友；风停后再组织抢点也可以。',
  '被标记的可能是任何一队的队员。看清倒计时和周围的克制关系，再决定集结位置。',
  '这关看队员数量，不看据点分。围栏开始收拢前先向内集结，避免队伍挤在角落。',
  '花盆与临阵换队同时启用。先绕开障碍组织抢点，第 20 秒后再留意被标记的队员。'
];
/** Build from the actual scenario so logs and in-game help describe challenge combinations too. */
export function arenaSceneLabel(config: ArenaConfig): string {
  const s=arenaScenario(config), events=arenaScenarioEvents(s).map((event:ArenaEventGuide):string => event.name);
  return `${config.mode==='challenge' ? `挑战${config.mission+1}·` : ''}${s.name} / ${events.length>0 ? events.join('+') : '平静庭院'}`;
}
/** Brief live explanations share the native message area; no new overlay or animation. */
export function arenaLiveNotice(r: ArenaRound, s: ArenaScenario): string {
  const t=r.tick/60;
  if(s.traitor && r.traitorId>0) {
    if(!r.traitorDone && t<r.traitorAt)return `标记队员 ${Math.ceil(r.traitorAt-t)} 秒后换队，护盾无法阻止`;
    if(r.traitorDone && t<r.traitorAt+3)return '标记队员已换队，留意附近的克制关系';
  }
  if(s.wind && t>=18 && t<20)return `风场还有 ${Math.ceil(20-t)} 秒：圈内队员将被向外推开`;
  if(s.wind && t>=20 && t<25)return '风场生效中：圈内双方都会被向外推开';
  if(s.shrink && t>=12 && t<15)return `围栏还有 ${Math.ceil(15-t)} 秒开始收拢，提前向内集结`;
  if(s.shrink && t>=15 && t<18)return '围栏开始收拢，可活动空间会逐渐变小';
  if(s.obstacles && t<5)return '花盆会挡路，队员会从空隙绕行';
  return '';
}
