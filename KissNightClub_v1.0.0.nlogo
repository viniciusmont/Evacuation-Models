;Copyright 2016 Silva, V.M; Scholl, M.V.
;
;Licensed under the Apache License, Version 2.0 (the "License");
;you may not use this file except in compliance with the License.
;You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
;Unless required by applicable law or agreed to in writing, software
;distributed under the License is distributed on an "AS IS" BASIS,
;WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;See the License for the specific language governing permissions and
;limitations under the License.

patches-own [exit? inside? stage?]
globals     [population exitcolor exit-final-patch exit-initial-patch p-e-ratio num-exits people-out alarm-actived]
turtles-own [exit]

;; initializes the model
to setup
 clear-all ;initialize model (clears all variables)
 set num-exits 1
 set exit-initial-patch -20
 set population initial-population ; occupants number
 setup-patches ;; draws the discotheque limits
 setup-turtles
 set p-e-ratio int(initial-population / 1)
 set people-out 0
 reset-ticks
end

;; draws discotheque
to setup-patches
 ; setup inside to 69,35% of grid 24.85x24.85 patches = 617.5patchs^2 (scale nightclub area)
 ask patches
  [ set exit? false
    set inside? (abs pycor < (.71 * max-pycor)) and (abs pxcor < (.71 * max-pxcor)) ]
 ; draws walls limit
 ask inside [ ask neighbors with [not inside?] [set pcolor grey] ]

 set alarm-actived false

 ;calc door size based on exit-width slider and at the start position of door
 set exit-final-patch (exit-initial-patch + exit-width)
 ask patches with [pxcor >= -20 and pxcor <= exit-final-patch and pycor = -25] [set pcolor green set exit? true]

 set-plot-y-range 0 population                      ; for the plot
 ask patches [ask inside [set pcolor white]]        ; draws discotheque floor as white

end

to setup-turtles
  set-default-shape turtles "person"
  ask n-of population inside [ sprout 1 ]
end

;; go procedure
to go
  tick
  ;move
  ask turtles [verify-inside]
  set population count turtles with [inside?]
  set alarm-actived false
  plot population
  if not any? turtles [set-plot-x-range 0 ticks stop]
end


;verify if has people inside of nightclub
to verify-inside
  ;If it have not an alarm active, people moves random
  if(not alarm-actived) [
    right (random 180) - 90

    forward 0.5
    if (any? patches in-cone 3 60 with  [pcolor = black]) [
      back 2
      right (random 180) - 90
      forward 1
    ]
  ]

  ;people who escaped
  set people-out int(initial-population - population)
end


;move
to move
    ;if it is not in the party
    ;disable and die
    if not inside?
    [ ifelse
      patch-ahead 1 = nobody
      [die]
      [move-to patch-ahead 1]
    ]
end

to set-minor-distance-exit
ask turtles
   [ set exit min-one-of exits [distance myself]
     set color [pcolor + 10] of exit ]
end

to move-out
  set-minor-distance-exit
  ask turtles [
    ifelse inside?
    [ let d distance exit
      let n neighbors with
      [ (not any? turtles-here) and (inside? or exit?) and (distance [exit] of myself < d)
        ]
     if any? n [face one-of n move-to patch-ahead 1]
    ]
    [ ifelse
      patch-ahead 1 = nobody
      [die]

      [move-to patch-ahead 1]
    ]
  ]
  if population = 0 [stop]
end

;; move turtles towards exit
to alarm
  go
  set alarm-actived true
  move-out
  if population = 0 [stop]
end

;; move turtles towards exit by step
to alarm-step
  move-out
end

;; Simple utilities
to-report inside report patches with [inside?] end
to-report exits  report patches with [exit?]   end
@#$#@#$#@
GRAPHICS-WINDOW
377
34
1097
775
35
35
10.0
1
10
1
1
1
0
0
0
1
-35
35
-35
35
1
1
1
ticks
30.0

BUTTON
26
34
89
67
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
159
35
254
68
go-out
reset-ticks\nalarm
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
92
34
155
67
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1119
32
1559
359
population
time-to-exit
people-out
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -14439633 true "" ""

MONITOR
128
184
192
229
NIL
population
0
1
11

SLIDER
26
81
187
114
initial-population
initial-population
100
1500
691
1
1
NIL
HORIZONTAL

MONITOR
46
183
121
228
time to exit
ticks
17
1
11

MONITOR
120
127
224
172
people/exit ratio
p-e-ratio
0
1
11

MONITOR
45
127
116
172
Disco area
24.85 * 24.85
0
1
11

MONITOR
241
127
326
172
People Out
people-out
17
1
11

BUTTON
263
35
348
68
Alarm Step
alarm-step
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
224
184
326
229
Alarm Actived
alarm-actived
17
1
11

SLIDER
199
82
347
115
exit-width
exit-width
1
7
3
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model replicates a Discotheque full of people. When an emergency occurs, for instance a fire, people must move to nearest exit.

## HOW IT WORKS

Discotheque is represented as a physical space with grey boundaries. Exits are randomly assigned with a random colour. People is also randomly distributed in the disco space. For each person, represented by a circle, the of the nearest exit is given.

The plot shows the evolution over time. Each person will move towards the nearest exit, but only if the space is not occupied by someone else. At each cycle (tick) people will move one position. Assuming that each position is has a meter radius, and that a "tick" is a second, they are moving a 1 meter/second (m/s).

## HOW TO USE IT

Press the SETUP button to initialize the model. The STEP button will show one cycle of the egress movement. GO button will start the egress procedure and will stop only when all occupants exit the discotheque.

User can change the number of initial population, number and width of exits, just by moving the corresponding slider.

Some notes:
> initial-population slider: range is 100-3000; increments of 100.
> there are eight exits, values range: 0-8 (exits 1-3) and 0-3 (exits 4-8)
> when the exit has value 0 means it is closed
> the value of the exit > 0 is the width in meters

Exits location:
> exit 1: bottom left; exit 2: bottom centre; exit 3: bottom right;
> exit 4: side left; exit 5: side right;
> exit 6: top left; exit 7: top centre; exit 8: top left;

## THINGS TO NOTICE

After setup, each occupant will change to the colour corresponding to the assigned exit.
Varying the exits location and width alters the evacuation time.

The graph shows the evolution in time of the evacuation process.

## THINGS TO TRY

User can change the number of the initial population and the exits number. This will permit to study the relation between the exits and population to determine the best ratio (people/exit).

## CREDITS AND REFERENCES

Based on NetLogo tutorial wiki (http://backspaces.net/wiki/NetLogo_Tutorial).
Adapted by Jo�o Em�lio Almeida and Zafeiris Kokkinogenis from ProDEI/FEUP, for MAMS course, August 2011.

Presented at 4th WISA 2012 - Workshop on Intelligent Systems and Applications, Madrid.

Almeida, J.E.; Kokkinogenis, Z.; Rossetti, R. (2012) NetLogo Implementation of an Evacuation Scenario. In: WISA'2012 (Fourth Workshop on Intelligent Systems and Applications), Madrid, Spain, June 20-23, 2012.

http://ieeexplore.ieee.org/xpl/articleDetails.jsp;jsessionid=h6yLQvsLy5G620LY93V141FQg0VBpjr2bwplhXkn21rbJqyGLkrY!-604091148?arnumber=6263226&contentType=Conference+Publications

## HOW TO CITE

If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:
- Almeida, J.E.; Kokkinogenis, Z.; Rossetti, R. (2012). NetLogo Implementation of an Evacuation Scenario.

In other publications, please use:
- Copyright 2012 Almeida, J.E.; Kokkinogenis, Z.; Rossetti, R. All rights reserved.

## COPYRIGHT NOTICE

Copyright 2012 Jo�o E. Almeida, Zafeiris Kokkinogenis; Rosaldo J. F. Rossetti.
All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:
a) this copyright notice is included.
b) this model will not be redistributed for profit without permission from Jo�o E. Almeida, Zafeiris Kokkinogenis; Rosaldo J. F. Rossetti.
Contact joao.emilio.almeida@fe.up.pt, pro08017@fe.up.pt or rossetti@fe.up.pt for appropriate licenses for redistribution for profit.

This model was created as part of the project for the course of MAMS, part of ProDEI Doctoral Program in Informatics Engineering, at FEUP (http://www.fe.up.pt).
http://sigarra.up.pt/feup/en/cur_geral.cur_view?pv_ano_lectivo=2012&pv_origem=CUR&pv_tipo_cur_sigla=D&pv_curso_id=679

## ACKNOWLEDGMENT

This project has been partially supported by FCT (Funda��o para a Ci�ncia e a Tecnologia), the Portuguese Agency for R&D, under grants SFRH/BD/72946/2010, SFRH/BD/67202/2009.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
