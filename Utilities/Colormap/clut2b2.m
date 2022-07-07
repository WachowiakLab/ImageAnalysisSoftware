function cmap = clut2b2(m)

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end

cmap = [0	1	13
0	2	20
0	3	27
0	3	33
0	3	39
0	4	45
0	5	51
0	6	57
0	9	63
0	9	69
0	10	75
0	12	81
0	12	87
0	13	93
0	13	99
0	14	105
0	15	111
0	15	117
0	18	123
0	21	128.9960938
0	24	134.9960938
0	26	140.9960938
0	29	146.9960938
0	32	152.9960938
0	35	158.9960938
0	38	164.9960938
0	41	170.9960938
0	44	176.9960938
0	47	182.9960938
0	50	188.9960938
0	53	193.9960938
0	55	199.9960938
0	57	205.9960938
0	59	211.9960938
0	61	217.9960938
0	63	223.9960938
0	64	228.9960938
0	65	233.9960938
0	66	238.9960938
0	67	244.9960938
0	68	250.9960938
0	69	254.9960938
0	70	254.9960938
0	71	254.9960938
0	72	254.9960938
0	73	254.9960938
0	74	254.9960938
0	75	254.9960938
0	76	254.9960938
0	77	254.9960938
0	78	254.9960938
0	79	254.9960938
0	80	254.9960938
0	84	254.9960938
0	87	254.9960938
0	91	254.9960938
0	94	254.9960938
0	98	254.9960938
0	101	254.9960938
0	105	254.9960938
0	108	254.9960938
0	112	254.9960938
0	115	254.9960938
0	119	254.9960938
0	122	254.9960938
0	126	254.9960938
0	128.9960938	254.9960938
0	132.9960938	254.9960938
0	135.9960938	254.9960938
0	139.9960938	254.9960938
0	142.9960938	254.9960938
0	146.9960938	246.9960938
0	149.9960938	239.9960938
0	153.9960938	231.9960938
0	156.9960938	223.9960938
0	160.9960938	215.9960938
0	163.9960938	208.9960938
0	167.9960938	200.9960938
0	170.9960938	192.9960938
0	174.9960938	184.9960938
0	177.9960938	177.9960938
0	181.9960938	169.9960938
0	184.9960938	161.9960938
0	188.9960938	154.9960938
0	191.9960938	146.9960938
0	195.9960938	138.9960938
0	198.9960938	130.9960938
0	202.9960938	124
0	205.9960938	116
0	209.9960938	108
0	212.9960938	100
0	216.9960938	93
0	219.9960938	85
0	223.9960938	77
0	226.9960938	70
0	230.9960938	62
7	233.9960938	54
13	237.9960938	46
20	240.9960938	39
26	244.9960938	31
33	247.9960938	23
39	251.9960938	15
46	254.9960938	8
52	254.9960938	0
59	254.9960938	0
65	254.9960938	0
72	254.9960938	0
78	254.9960938	0
85	254.9960938	0
92	254.9960938	0
98	254.9960938	0
105	254.9960938	0
111	254.9960938	0
118	254.9960938	0
124	254.9960938	0
130.9960938	254.9960938	0
136.9960938	254.9960938	0
143.9960938	254.9960938	0
149.9960938	254.9960938	0
156.9960938	254.9960938	0
162.9960938	254.9960938	0
169.9960938	254.9960938	0
176.9960938	254.9960938	0
182.9960938	254.9960938	0
189.9960938	254.9960938	0
195.9960938	254.9960938	0
202.9960938	254.9960938	0
208.9960938	254.9960938	0
215.9960938	254.9960938	0
221.9960938	254.9960938	0
228.9960938	254.9960938	0
234.9960938	254.9960938	0
241.9960938	254.9960938	0
247.9960938	254.9960938	0
253.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	254.9960938	0
254.9960938	253.9960938	0
254.9960938	249.9960938	0
254.9960938	247.9960938	0
254.9960938	243.9960938	0
254.9960938	239.9960938	0
254.9960938	236.9960938	0
254.9960938	232.9960938	0
254.9960938	229.9960938	0
254.9960938	225.9960938	0
254.9960938	221.9960938	0
254.9960938	218.9960938	0
254.9960938	214.9960938	0
254.9960938	210.9960938	0
254.9960938	207.9960938	0
254.9960938	203.9960938	0
254.9960938	199.9960938	0
254.9960938	196.9960938	0
254.9960938	192.9960938	0
254.9960938	188.9960938	0
254.9960938	185.9960938	0
254.9960938	181.9960938	0
254.9960938	177.9960938	0
254.9960938	174.9960938	0
254.9960938	170.9960938	0
254.9960938	167.9960938	0
254.9960938	163.9960938	0
254.9960938	159.9960938	0
254.9960938	156.9960938	0
254.9960938	152.9960938	0
254.9960938	148.9960938	0
254.9960938	145.9960938	0
254.9960938	141.9960938	0
254.9960938	137.9960938	0
254.9960938	134.9960938	0
254.9960938	130.9960938	0
254.9960938	128	0
254.9960938	124	0
254.9960938	120	0
254.9960938	117	0
254.9960938	113	0
254.9960938	109	0
254.9960938	106	0
254.9960938	102	0
254.9960938	98	0
254.9960938	95	0
254.9960938	91	0
254.9960938	87	0
254.9960938	84	0
254.9960938	80	0
254.9960938	76	0
254.9960938	73	0
254.9960938	69	0
254.9960938	66	0
252.9960938	62	0
254.9960938	58	0
254.9960938	55	0
254.9960938	51	0
254.9960938	47	0
254.9960938	44	0
254.9960938	40	0
254.9960938	36	0
254.9960938	33	0
254.9960938	29	0
254.9960938	26	0
254.9960938	22	0
254.9960938	18	0
254.9960938	15	0
254.9960938	11	0
254.9960938	7	0
254.9960938	4	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0
254.9960938	0	0];
cmap(231:256, 1) = linspace(255,148, numel(231:256));
cmap = cmap./255;

P = size(cmap,1);
cmap = interp1(1:P, cmap, linspace(1,P,m), 'linear');