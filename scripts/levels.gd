class_name Levels
extends RefCounted

## 关卡数据 v5：四关均为原创大地图式场景插画（assets/scene_*.webp，
## 无墙户外景观、细暖棕线、柔和色、花田/小径/摊位成片，独立构图）。
## 目标物品以热点标定：{kind, color, x, y, r}，坐标为世界坐标
## （世界 1600x1067，对应原图 1920x1280 的归一化定位换算）。
## intro/outro 为原创对话。

const DATA: Array = [
	{
		"name": "小镇街道",
		"scene": "res://assets/scene_street_anim.webp",
		"hints": 3,
		"par_time": 120,
		"targets": [
			{"kind": "apple", "color": "红", "x": 325, "y": 436, "r": 48},
			{"kind": "key", "color": "金", "x": 528, "y": 72, "r": 42},
			{"kind": "book", "color": "蓝", "x": 726, "y": 807, "r": 48},
			{"kind": "cup", "color": "绿", "x": 619, "y": 605, "r": 44},
			{"kind": "hat", "color": "紫", "x": 133, "y": 189, "r": 48},
			{"kind": "balloon", "color": "橙", "x": 1189, "y": 700, "r": 52},
		],
		# 彩蛋：不在清单里，点中只做本色动作、不计分、不收集。
		# who=画面里实际是什么，act=动作，say=点中时飘的字。
		# sprite=抠出来的透明底单张（tools/extract_street.py 生成），
		# srect=单张在世界里的矩形 [x0,y0,x1,y1]，精灵按它摆放；
		# 底板 scene_street_anim.webp 里人物已抠掉、补上了背景。
		"reactives": [
			{"who": "灰猫", "x": 893, "y": 729, "r": 46, "act": "yawn", "say": "喵～", "sprite": "res://assets/sprites/street/cat_grey.png", "srect": [836.7, 672.5, 948.3, 785.0]},
			{"who": "橘猫", "x": 435, "y": 518, "r": 44, "act": "yawn", "say": "哈～", "sprite": "res://assets/sprites/street/cat_orange.png", "srect": [378.3, 461.7, 490.8, 573.3]},
			{"who": "小鸟", "x": 587, "y": 892, "r": 36, "act": "chirp", "say": "啾啾♪", "sprite": "res://assets/sprites/street/bird.png", "srect": [536.7, 841.7, 636.7, 941.7]},
			{"who": "浇水壶", "x": 1293, "y": 726, "r": 42, "act": "pour", "say": "哗啦", "sprite": "res://assets/sprites/street/kettle.png", "srect": [1233.3, 666.7, 1351.7, 784.2]},
			{"who": "向日葵", "x": 910, "y": 184, "r": 44, "act": "sway", "say": "", "sprite": "res://assets/sprites/street/sunflower.png", "srect": [847.5, 121.7, 971.7, 245.8]},
		],
		# 住户：场景里所有人/动物/花草，不在清单里。平时待机呼吸，
		# 每隔几秒自己动一下，点中做本色动作、不计分、不收集。
		# idle: breathe=呼吸起伏，sway=左右轻摆。
		# 2026-11-24 位置按场景图重核：粉帽小人/提篮人/紫衣小人/
		# 黑白猫/路灯原来偏了 30-80，提篮绿衣人偏了 35；另补一只
		# 右上灰猫（原来漏了）。
		"inhabitants": [
			{"who": "粉衣小人", "x": 470, "y": 255, "r": 30, "act": "bob", "say": "逛逛～", "idle": "breathe", "sprite": "res://assets/sprites/street/person_pink.png", "srect": [421.7, 206.7, 517.5, 302.5]},
			{"who": "提篮绿衣人", "x": 928, "y": 360, "r": 30, "act": "bob", "say": "", "idle": "breathe", "sprite": "res://assets/sprites/street/person_basket_green.png", "srect": [880.0, 311.7, 975.8, 407.5]},
			{"who": "粉帽小人", "x": 709, "y": 500, "r": 30, "act": "bob", "say": "你好呀", "idle": "breathe", "sprite": "res://assets/sprites/street/person_hat_pink.png", "srect": [660.8, 451.7, 756.7, 547.5]},
			{"who": "提篮人", "x": 765, "y": 515, "r": 30, "act": "bob", "say": "", "idle": "breathe", "sprite": "res://assets/sprites/street/person_basket.png", "srect": [716.7, 466.7, 812.5, 562.5]},
			{"who": "紫衣小人", "x": 829, "y": 969, "r": 30, "act": "bob", "say": "", "idle": "breathe", "sprite": "res://assets/sprites/street/person_purple.png", "srect": [780.8, 920.8, 876.7, 1016.7]},
			{"who": "黑白猫", "x": 1186, "y": 1036, "r": 30, "act": "yawn", "say": "喵～", "idle": "breathe", "sprite": "res://assets/sprites/street/cat_bw.png", "srect": [1137.5, 987.5, 1233.3, 1066.7]},
			{"who": "路灯", "x": 1181, "y": 823, "r": 36, "act": "glow", "say": "", "idle": "breathe", "sprite": "res://assets/sprites/street/lamp.png", "srect": [1145.8, 790.0, 1215.8, 1060.0]},
			{"who": "粉花丛", "x": 292, "y": 933, "r": 40, "act": "sway", "say": "", "idle": "sway", "sprite": "res://assets/sprites/street/flowers_pink.png", "srect": [226.7, 876.7, 356.7, 988.3]},
			{"who": "灰猫（右上）", "x": 1019, "y": 330, "r": 28, "act": "yawn", "say": "喵～", "idle": "breathe", "sprite": "res://assets/sprites/street/cat_grey2.png", "srect": [970.8, 281.7, 1066.7, 377.5]},
		],
		"intro": [
			["店长猫 · 阿橘", "小满在小镇街上逛了一圈，把心爱的宝贝掉了一路！"],
			["小满", "拜托拜托！清单在右边，一共 6 样。街道可以拖动、滚轮放大，慢慢看～"],
		],
		"outro": [
			["小满", "全都找到啦！谢谢阿橘店长！"],
			["店长猫 · 阿橘", "小意思。下次逛街，记得把包的拉链拉好。"],
		],
	},
	{
		"name": "热闹市集",
		"scene": "res://assets/scene_market.webp",
		"hints": 3,
		"par_time": 180,
		"targets": [
			{"kind": "teapot", "color": "黄", "x": 285, "y": 591, "r": 54},
			{"kind": "candle", "color": "红", "x": 296, "y": 252, "r": 42},
			{"kind": "clock", "color": "白", "x": 1416, "y": 160, "r": 52},
			{"kind": "flower", "color": "粉", "x": 499, "y": 828, "r": 46},
			{"kind": "scissors", "color": "银", "x": 960, "y": 838, "r": 44},
			{"kind": "glasses", "color": "蓝", "x": 1050, "y": 821, "r": 50},
			{"kind": "boot", "color": "棕", "x": 1155, "y": 605, "r": 52},
			{"kind": "gift", "color": "粉", "x": 1309, "y": 379, "r": 52},
		],
		"reactives": [
			{"who": "向日葵", "x": 290, "y": 816, "r": 46, "act": "sway", "say": ""},
			{"who": "布料堆", "x": 875, "y": 790, "r": 48, "act": "flutter", "say": ""},
			{"who": "灯笼", "x": 267, "y": 196, "r": 40, "act": "glow", "say": ""},
			{"who": "蓝花", "x": 1467, "y": 825, "r": 36, "act": "sway", "say": ""},
		],
		"inhabitants": [
			{"who": "蓝衣小人", "x": 633, "y": 125, "r": 28, "act": "bob", "say": "逛逛～", "idle": "breathe"},
			{"who": "棕衣小人", "x": 592, "y": 283, "r": 28, "act": "bob", "say": "", "idle": "breathe"},
			{"who": "蓝衣小人", "x": 983, "y": 325, "r": 20, "act": "bob", "say": "", "idle": "breathe"},
			{"who": "棕衣小人", "x": 1025, "y": 325, "r": 20, "act": "bob", "say": "你好呀", "idle": "breathe"},
			{"who": "蓝衣小人", "x": 542, "y": 567, "r": 20, "act": "bob", "say": "", "idle": "breathe"},
			{"who": "红衣小人", "x": 558, "y": 608, "r": 20, "act": "bob", "say": "", "idle": "breathe"},
			{"who": "提篮人", "x": 942, "y": 550, "r": 28, "act": "bob", "say": "", "idle": "breathe"},
			{"who": "蓝衣小人", "x": 1133, "y": 100, "r": 28, "act": "bob", "say": "", "idle": "breathe"},
		],
		"intro": [
			["店长猫 · 阿橘", "市集开市啦！露露的摊位被人群挤得乱七八糟，8 样东西散落在各个摊位里。"],
			["厨师 · 露露", "我的茶壶、剪刀……拜托帮我找回来！茶壶多半还在茶摊上。"],
		],
		"outro": [
			["厨师 · 露露", "齐啦！今晚能准时收摊了！"],
			["店长猫 · 阿橘", "市集虽大，可难不倒我们。"],
		],
	},
	{
		"name": "阳光花园",
		"scene": "res://assets/scene_garden.webp",
		"hints": 3,
		"par_time": 260,
		"targets": [
			{"kind": "mushroom", "color": "红", "x": 502, "y": 576, "r": 42},
			{"kind": "star", "color": "黄", "x": 467, "y": 511, "r": 40},
			{"kind": "fish", "color": "蓝", "x": 1030, "y": 407, "r": 58},
			{"kind": "umbrella", "color": "粉", "x": 312, "y": 955, "r": 64},
			{"kind": "sock", "color": "橙", "x": 714, "y": 701, "r": 46},
			{"kind": "gift", "color": "金", "x": 1056, "y": 596, "r": 50},
			{"kind": "lamp", "color": "紫", "x": 498, "y": 786, "r": 46},
			{"kind": "hat", "color": "绿", "x": 693, "y": 924, "r": 50},
			{"kind": "candle", "color": "白", "x": 787, "y": 915, "r": 44},
			{"kind": "balloon", "color": "红", "x": 1125, "y": 495, "r": 54},
		],
		"reactives": [
			{"who": "白兔子", "x": 222, "y": 353, "r": 40, "act": "hop", "say": "蹦"},
			{"who": "橘猫", "x": 1333, "y": 810, "r": 46, "act": "yawn", "say": "哈～"},
			{"who": "小鸟", "x": 1181, "y": 645, "r": 36, "act": "chirp", "say": "啾啾♪"},
			{"who": "石灯", "x": 1261, "y": 538, "r": 42, "act": "glow", "say": ""},
		],
		"inhabitants": [
			{"who": "小鸟", "x": 891, "y": 75, "r": 28, "act": "chirp", "say": "啾啾♪", "idle": "breathe"},
			{"who": "小鸟", "x": 874, "y": 211, "r": 28, "act": "chirp", "say": "", "idle": "breathe"},
			{"who": "小鸟", "x": 1002, "y": 286, "r": 28, "act": "chirp", "say": "", "idle": "breathe"},
			{"who": "小鸟", "x": 1088, "y": 304, "r": 28, "act": "chirp", "say": "啾啾♪", "idle": "breathe"},
			{"who": "小鸟", "x": 949, "y": 740, "r": 28, "act": "chirp", "say": "", "idle": "breathe"},
			{"who": "粉花丛", "x": 250, "y": 83, "r": 40, "act": "sway", "say": "", "idle": "sway"},
			{"who": "蓝花丛", "x": 1458, "y": 250, "r": 40, "act": "sway", "say": "", "idle": "sway"},
			{"who": "石灯", "x": 325, "y": 550, "r": 36, "act": "glow", "say": "", "idle": "breathe"},
		],
		"intro": [
			["店长猫 · 阿橘", "园丁刺猬奶奶的花园办派对，10 样东西被草丛和花丛藏起来了。"],
			["刺猬奶奶", "慢慢找，孩子。花园大，多放大、多拖动看看。实在找不到，就用提示。"],
		],
		"outro": [
			["刺猬奶奶", "一件不少！派对可以开始啦。"],
			["店长猫 · 阿橘", "呼——这片花园，比看上去还要深呢。"],
		],
	},
	{
		"name": "秋日公园",
		"scene": "res://assets/scene_park.webp",
		"hints": 3,
		"par_time": 280,
		"targets": [
			{"kind": "star", "color": "黄", "x": 133, "y": 142, "r": 46},
			{"kind": "mushroom", "color": "红", "x": 717, "y": 140, "r": 46},
			{"kind": "key", "color": "金", "x": 760, "y": 534, "r": 44},
			{"kind": "balloon", "color": "红", "x": 717, "y": 659, "r": 54},
			{"kind": "book", "color": "蓝", "x": 803, "y": 734, "r": 50},
			{"kind": "candle", "color": "白", "x": 928, "y": 686, "r": 48},
			{"kind": "hat", "color": "绿", "x": 822, "y": 925, "r": 50},
			{"kind": "apple", "color": "红", "x": 474, "y": 941, "r": 48},
			{"kind": "fish", "color": "蓝", "x": 1256, "y": 975, "r": 54},
			{"kind": "gift", "color": "金", "x": 1525, "y": 897, "r": 50},
		],
		"reactives": [
			{"who": "狐狸", "x": 282, "y": 160, "r": 44, "act": "yawn", "say": "呼～"},
			{"who": "白兔子", "x": 1203, "y": 397, "r": 42, "act": "hop", "say": "蹦"},
			{"who": "虎斑猫", "x": 248, "y": 652, "r": 44, "act": "yawn", "say": "哈～"},
			{"who": "蓝花", "x": 869, "y": 295, "r": 36, "act": "sway", "say": ""},
		],
		"inhabitants": [
			{"who": "小鸟", "x": 1165, "y": 187, "r": 28, "act": "chirp", "say": "啾啾♪", "idle": "breathe"},
			{"who": "小鸟", "x": 1011, "y": 270, "r": 28, "act": "chirp", "say": "", "idle": "breathe"},
			{"who": "小鸟", "x": 1134, "y": 280, "r": 28, "act": "chirp", "say": "", "idle": "breathe"},
			{"who": "小鸟", "x": 1261, "y": 473, "r": 28, "act": "chirp", "say": "啾啾♪", "idle": "breathe"},
			{"who": "竹林", "x": 208, "y": 375, "r": 48, "act": "sway", "say": "", "idle": "sway"},
			{"who": "竹林", "x": 1542, "y": 317, "r": 48, "act": "sway", "say": "", "idle": "sway"},
			{"who": "粉花丛", "x": 583, "y": 333, "r": 40, "act": "sway", "say": "", "idle": "sway"},
			{"who": "紫花丛", "x": 333, "y": 583, "r": 40, "act": "sway", "say": "", "idle": "sway"},
			{"who": "石灯", "x": 1458, "y": 817, "r": 36, "act": "glow", "say": "", "idle": "breathe"},
		],
		"intro": [
			["店长猫 · 阿橘", "秋游的客人把东西丢了满公园，连松鼠都帮忙藏了几件！"],
			["登山客 · 小鹿", "拜托了！清单 10 样。公园很大，多拖动、多放大，花丛里也要看仔细。"],
		],
		"outro": [
			["登山客 · 小鹿", "全找到了！这下能安心去野餐啦。"],
			["店长猫 · 阿橘", "秋天的公园真大啊——下次委托，可别再选这么大的地方了。"],
		],
	},
]
