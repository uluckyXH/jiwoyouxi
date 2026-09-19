import { TangramPoint, TangramPose, tangramBounds, tangramPolygon } from './TangramGeometry';

export interface TangramLevel { id: string; title: string; caption: string; guide: boolean; poses: TangramPose[]; }
export const TANGRAM_WORLD_WIDTH: number = 8;
export const TANGRAM_WORLD_HEIGHT: number = 10.9;
export const TANGRAM_LEVELS: TangramLevel[] = [
  {
    "id": "window",
    "title": "一扇小窗",
    "caption": "让七种颜色，住进同一扇窗。",
    "guide": true,
    "poses": [
      {
        "id": 0,
        "x": 0,
        "y": 0,
        "turn": 0,
        "flip": false
      },
      {
        "id": 1,
        "x": 0,
        "y": 0,
        "turn": 2,
        "flip": false
      },
      {
        "id": 2,
        "x": 0,
        "y": -2,
        "turn": 0,
        "flip": false
      },
      {
        "id": 3,
        "x": -1,
        "y": 0,
        "turn": 4,
        "flip": false
      },
      {
        "id": 4,
        "x": 0,
        "y": 0,
        "turn": 6,
        "flip": false
      },
      {
        "id": 5,
        "x": -1,
        "y": -1,
        "turn": 0,
        "flip": false
      },
      {
        "id": 6,
        "x": 0,
        "y": -1,
        "turn": 0,
        "flip": false
      }
    ]
  },
  {
    "id": "home",
    "title": "暖暖小屋",
    "caption": "屋顶下，藏着一个慢悠悠的下午。",
    "guide": true,
    "poses": [
      {
        "id": 0,
        "x": 0,
        "y": 0,
        "turn": 4,
        "flip": false
      },
      {
        "id": 1,
        "x": 0,
        "y": 0,
        "turn": 6,
        "flip": false
      },
      {
        "id": 2,
        "x": 0,
        "y": 1,
        "turn": 0,
        "flip": false
      },
      {
        "id": 3,
        "x": -1,
        "y": 0,
        "turn": 0,
        "flip": false
      },
      {
        "id": 4,
        "x": 1,
        "y": 1,
        "turn": 0,
        "flip": true
      },
      {
        "id": 5,
        "x": 0,
        "y": 0,
        "turn": 0,
        "flip": false
      },
      {
        "id": 6,
        "x": 0,
        "y": 0,
        "turn": 2,
        "flip": false
      }
    ]
  },
  {
    "id": "boat",
    "title": "纸船出发",
    "caption": "风很轻，刚好送小船去旅行。",
    "guide": true,
    "poses": [
      {
        "id": 0,
        "x": 0,
        "y": 0,
        "turn": 4,
        "flip": false
      },
      {
        "id": 1,
        "x": 0,
        "y": 0,
        "turn": 6,
        "flip": false
      },
      {
        "id": 2,
        "x": -1.5,
        "y": 1,
        "turn": 4,
        "flip": false
      },
      {
        "id": 3,
        "x": 0.5,
        "y": 0,
        "turn": 0,
        "flip": false
      },
      {
        "id": 4,
        "x": -0.5,
        "y": 1,
        "turn": 2,
        "flip": true
      },
      {
        "id": 5,
        "x": -0.5,
        "y": 0,
        "turn": 0,
        "flip": false
      },
      {
        "id": 6,
        "x": 2.5,
        "y": 0,
        "turn": 0,
        "flip": true
      }
    ]
  },
  {
    "id": "cat",
    "title": "翘尾小猫",
    "caption": "喵，小猫在院子里晒太阳。",
    "guide": false,
    "poses": [
      {
        "id": 0,
        "x": 0,
        "y": 0,
        "turn": 0,
        "flip": false
      },
      {
        "id": 1,
        "x": 2,
        "y": 2,
        "turn": 4,
        "flip": false
      },
      {
        "id": 2,
        "x": 1,
        "y": 0,
        "turn": 4,
        "flip": false
      },
      {
        "id": 3,
        "x": 0,
        "y": -1,
        "turn": 6,
        "flip": false
      },
      {
        "id": 4,
        "x": 2,
        "y": -1,
        "turn": 4,
        "flip": false
      },
      {
        "id": 5,
        "x": 0,
        "y": 2,
        "turn": 0,
        "flip": false
      },
      {
        "id": 6,
        "x": 2,
        "y": 2,
        "turn": 6,
        "flip": false
      }
    ]
  },
  {
    "id": "chick",
    "title": "早安鸡仔",
    "caption": "小鸡把第一声早安，送给你。",
    "guide": false,
    "poses": [
      {
        "id": 0,
        "x": 0,
        "y": 0,
        "turn": 0,
        "flip": false
      },
      {
        "id": 1,
        "x": 2,
        "y": 2,
        "turn": 4,
        "flip": false
      },
      {
        "id": 2,
        "x": 2,
        "y": 1,
        "turn": 6,
        "flip": false
      },
      {
        "id": 3,
        "x": 4,
        "y": 0.5,
        "turn": 0,
        "flip": false
      },
      {
        "id": 4,
        "x": 3,
        "y": 0,
        "turn": 6,
        "flip": false
      },
      {
        "id": 5,
        "x": 3,
        "y": 0,
        "turn": 0,
        "flip": false
      },
      {
        "id": 6,
        "x": -2,
        "y": 0,
        "turn": 0,
        "flip": false
      }
    ]
  },
  {
    "id": "rabbit",
    "title": "花耳小兔",
    "caption": "蹦到花丛边，听听春天的声音。",
    "guide": false,
    "poses": [
      {
        "id": 0,
        "x": 0,
        "y": 0,
        "turn": 0,
        "flip": false
      },
      {
        "id": 1,
        "x": 2,
        "y": 2,
        "turn": 4,
        "flip": false
      },
      {
        "id": 2,
        "x": 1,
        "y": 2,
        "turn": 0,
        "flip": false
      },
      {
        "id": 3,
        "x": -0.5,
        "y": -1,
        "turn": 4,
        "flip": false
      },
      {
        "id": 4,
        "x": 2,
        "y": 0,
        "turn": 0,
        "flip": false
      },
      {
        "id": 5,
        "x": -0.5,
        "y": -1,
        "turn": 0,
        "flip": false
      },
      {
        "id": 6,
        "x": 0,
        "y": -1,
        "turn": 6,
        "flip": false
      }
    ]
  }
];

export function tangramLevel(id: string): TangramLevel {
  return TANGRAM_LEVELS.find((level: TangramLevel): boolean => level.id === id) || TANGRAM_LEVELS[0];
}

export function tangramSolution(id: string): TangramPose[] {
  const level = tangramLevel(id);
  const b = tangramBounds(level.poses.map(tangramPolygon));
  return level.poses.map((p: TangramPose): TangramPose => ({ id: p.id,
    x: p.x + 4 - b.x - b.width / 2, y: p.y + 3.25 - b.y - b.height / 2,
    turn: p.turn, flip: p.flip }));
}

export function tangramTarget(id: string): TangramPoint[][] { return tangramSolution(id).map(tangramPolygon); }

export function tangramTray(): TangramPose[] {
  return [
    { id: 0, x: .5, y: 7.05, turn: 0, flip: false },
    { id: 1, x: 4.8, y: 9.05, turn: 4, flip: false },
    { id: 2, x: 6.5, y: 7.05, turn: 0, flip: false },
    { id: 3, x: .5, y: 9.35, turn: 0, flip: false },
    { id: 4, x: 2, y: 9.35, turn: 0, flip: false },
    { id: 5, x: 3.55, y: 9.35, turn: 0, flip: false },
    { id: 6, x: 5.25, y: 9.2, turn: 0, flip: false }
  ];
}
