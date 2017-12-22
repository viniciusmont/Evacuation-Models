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

globals     [flag-stop num-exits swaps fire alarm-actived people-out actual-panic-ticks panic-tick-start initial-population scared-people percent-happy  ;;Percentage of agents that are human.
  percent-panic  ;;Percentage of agents that are zombies.
  ]
patches-own [exit? inside? wall? board? flood floods]
turtles-own [exit flood-index last-move speed]
breed [peoples_happy]
breed [peoples_panic]

to setup
  clear-all
  random-seed 1 ; use any number you'd like for the seed.
  setup-patches
  setup-turtles
  set num-exits 3
  set alarm-actived false
  set flag-stop false
  reset-ticks
end

to go
  tick
  ask turtles [move]

  reallocate-turtles
  if not any? turtles [set-plot-x-range 0 ticks stop]
  if (flag-stop) [stop]
end

to setup-agents ;; Create the desired number of each breed on random patches.
  set-default-shape peoples_happy "person"
  set-default-shape peoples_panic "person"

  ask n-of population patches
    [ sprout-peoples_happy 1
      [ set color blue
        set speed 3] ]
end

to setup-patches

  ask patches
  [ set exit? false
    set board? false
    set inside? (abs pycor < (.7 * max-pycor)) and (abs pxcor < (.7 * max-pxcor)) ]

  ask inside [ ask neighbors with [not inside?] [set pcolor grey set wall? true] ]

    ;Obstacles
  ask n-of obstacles inside with [not any? neighbors4 with [exit?]]
  [ set pcolor grey set inside? false set wall? true]

  ask patches with [pcolor = gray or pcolor = 5] [set inside? false set wall? true]

  ;bottom Exit door
  ask patches with [pxcor >= -3 and pxcor <= 0 and pycor = -25] [set wall? false set exit? true set pcolor (green)]

  paredes

  ;Walls floods
  ask patches [set floods []]
  foreach sort exits [ flood-fill ? ask patches [set floods lput flood floods] ]

  set alarm-actived false
end

to nbr-doors-and-signals
  ;top door
  ask patches with [pxcor >= -8 and pxcor <= -6 and pycor = 25] [set wall? false set exit? true set pcolor (green)]

  ask patches with [pxcor >= -3 and pxcor <= 0 and pycor = -20][set inside? true set exit? false set board? false set pcolor 9.9]

  ;Correct and Extra exit signal boards
  ask patch -21 -14 [ set pcolor lime set board? true set inside? true]
  ask patch -10 9 [ set pcolor lime set board? true set inside? true]
  ask patch -8 -8 [ set pcolor lime set board? true set inside? true]
  ask patch 8 8 [ set pcolor lime set board? true set inside? true]
  ask patch 9 -8 [ set pcolor lime set board? true set inside? true]
end

to scenario-without-nbr
  ;Exit Signal Board
  ask patch -10 -8 [ set pcolor lime set board? true set inside? true]
  ask patch 6 8 [ set pcolor blue set board? true set inside? true]
  ask patch 9 -6 [ set pcolor 25 set board? true set inside? true]

  ;Fake Bathrooms Exit
  ask patch -4 19 [ set exit? true set pcolor (blue)]
  ask patch 24 -19 [ set exit? true set pcolor 25]
end

to setup-turtles
  set-default-shape turtles agent-shape

  ask n-of population inside
  [
    sprout-peoples_happy 1
    [ set color brown
      set size agent-size]
  ]
end

to reallocate-turtles
  ask turtles with [pcolor = 16 or pcolor = 29 or pcolor = 37 or pcolor = 15]
    [
      set heading 180
      fd 1
    ]

  ask turtles with [pcolor = 5]
    [
      move-to patch-ahead 1
    ]
end

to move-around
  ; if alarm isn't activated, people move randonly inside the Nightclub area
   right (random 180) - 90

   ; if any people saw outsidescholl patches then they return to inside of the Nightclub area
   if (any? patches in-cone 3 45 with [pcolor = black])
   [
     back 2
     right (random 180) - 90
   ]

   ; get possibles patches to walk inside of the Nightclub area
   let possibles (patches in-cone 3 45 with [pcolor = 9.9]);

   if (any? possibles)
   [
     move-to one-of possibles
   ]
end

to move
  ifelse (not alarm-actived)
  [move-around]
  [
    set actual-panic-ticks (ticks - panic-tick-start)

    if (actual-panic-ticks >= 80 and (not NBR))
    [
      ifelse (initial-population = 691)
      [
        ask patches with [pxcor >= -3 and pxcor <= 0 and pycor = -20][set inside? true set wall? false set exit? false set board? false set flood 9999 set pcolor 9.9]
        print "entreiaqui"
      ]
      [
        if(actual-panic-ticks >= 140)
        [
          ask patches with [pxcor >= -3 and pxcor <= 0 and pycor = -20][set inside? true set wall? false set exit? false set board? false set flood 9999 set pcolor 9.9]
        ]
      ]
    ]

    ;if this turtle had an defined exit then they move to
     ifelse (exit != 0)
     [
       ifelse inside?
       [ let i flood-index
         let n0 neighbors with [ (inside? or exit?) and (item i floods < item i [floods] of myself) ]
         let n n0 with [ (not any? turtles-here) ]
         let frust (turtle-set [turtles-here with [frustrated?]] of n0)
         set frust frust with [ item flood-index [floods] of myself < item flood-index floods ]
         ifelse any? n [go-to one-of n] [if frustrated? and any? frust [swap one-of frust]] ]
       [ ifelse patch-ahead 1 = nobody [ set people-out people-out + 1 die] [move-to patch-ahead 1]]
     ]
     [
       move-around

        ;if they can see fire then
        if (any? patches in-cone 6 25 with [pcolor = 15]) or (any? peoples_panic in-cone 3 15)
        [
          ;get the closest exit or exit indication board of they
          let board-with-min-distance-myself min-one-of boards [distance myself]

          ;set the exit of color of the closest indication board
          set exit min-one-of exits [[pcolor] of board-with-min-distance-myself]
          set color [pcolor] of exit
          set flood-index position 0 [floods] of exit
          set breed peoples_panic
          set speed scared-speed

          ; if any people not scared, sum new scared people
          if (scared-people != population)
             [set scared-people scared-people + 1
             ]
        ]
     ]
  ]
end

to panic
  tick

  if (not alarm-actived)
  [ set panic-tick-start ticks
    print panic-tick-start
  ]

  fire-start ; fire
  set alarm-actived true
  if not any? turtles [set-plot-x-range 0 ticks stop]

  ;if NBR is deactivated, someone was evacuated and the number of turtles with exit color inside = 0
  ;flag stop is change to true and simulation will end
;  if((not NBR) and
  if (people-out > 0) and (count turtles with [color = 55 and (inside?)] = 0);)
  [
    ask turtles with [color = 55] [die]
    set flag-stop true
    stop
  ]
end

;; Draw and Setup Fire
to fire-start
  set fire patches with [(distancexy (-0.5 * max-pxcor) (0.6 * max-pycor)) < 3]
  ask fire [ set pcolor 15 ]
end

;; Draw Nightclub
to paredes
  ask inside [set pcolor 9.9]

  ;with free entry corridor
  ask patches with [pxcor >= -2 and pxcor <= 2 and pycor = -20] [set pcolor gray set inside? false set wall? true]

  ;Stage1 Walls
  ask patches with [pxcor >= -24 and pxcor <= -10 and pycor = 18] [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor = -9 and pycor <= 25 and pycor >= 10] [set pcolor gray set inside? false set wall? true]
  ;ask patch -8 18 [ set pcolor gray set inside? false set wall? true]

  ask patches with [pxcor = -9 and pycor <= 5 and pycor >= -3] [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor = -9 and pycor <= -8 and pycor >= -20] [set pcolor gray set inside? false set wall? true]

  ;mesanimo
  ask patches with [pxcor <= -10 and pxcor >= -20 and pycor = -15] [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor = -20 and pycor >= -20 and pycor <= -16] [set pcolor gray set inside? false set wall? true]

  ;mesanimo color
  ask patches with [pxcor <= -10 and pxcor >= -19 and pycor >= -20 and pycor <= -16] [set pcolor 37]


  ;Stage1 Color
  ask patches with [pxcor >= -24 and pxcor <= -10 and pycor >= 19 and pycor <= 24] [set pcolor 29]

  ;Top Bathroom Walls
  ask patches with [pxcor = 9 and pycor <= 24 and pycor >= 16] [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor = 9 and pycor <= 24 and pycor >= 16] [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor = 9 and pycor <= 12 and pycor >= 10] [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor <= 8 and pxcor >= 5 and pycor = 16]  [set pcolor gray set inside? false set wall? true]

  ;Top Bathrooms
  ask patches with [pxcor = -5 and pycor <= 25 and pycor >= 9] [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor >= -4 and pxcor <= 9 and pycor = 9]  [set pcolor gray set inside? false set wall? true]

  ;Stage2 Walls
  ask patches with [pxcor >= 10 and pxcor <= 24 and pycor = 19][set pcolor gray set inside? false]

  ;Stage2 Color
  ask patches with [pxcor >= 10 and pxcor <= 24 and pycor <= 24 and pycor >= 20] [set pcolor 29]

  ;Bar Walls
  ask patches with [pxcor >= -24 and pxcor <= -21 and pycor = 2]  [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor = -21 and pycor <= 1 and pycor >= -8]   [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor >= -24 and pxcor <= -22 and pycor = -8] [set pcolor gray set inside? false set wall? true]

  ;Bar Color
  ask patches with [pxcor >= -24 and pxcor <= -22 and pycor <= 1 and pycor >= -7] [set pcolor 16]

  ask patches with [pxcor <= -3 and pxcor >= -20 and pycor = -20] [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor >= 3 and pxcor <= 13 and pycor = -20]   [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor = 13 and pycor >= -24 and pycor <= -21] [set pcolor gray set inside? false set wall? true]

;Bottom Bathroom Walls
  ask patches with [pxcor = 13 and pycor <= -12 and pycor >= -16] [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor >= 14 and pxcor <= 24 and pycor = -12]  [set pcolor gray set inside? false set wall? true]

  ask patches with [pxcor = 10 and pycor <= -5 and pycor >= -16]  [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor = 10 and pycor <= -19 and pycor >= -20] [set pcolor gray set inside? false set wall? true]

;Bar2 Walls
  ask patches with [pxcor >= 21 and pxcor <= 24 and pycor = 0]  [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor >= 21 and pxcor <= 24 and pycor = 10] [set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor = 21 and pycor >= 1 and pycor <= 9]   [set pcolor gray set inside? false set wall? true]

  ask patches with [pxcor >= 22 and pxcor <= 24 and pycor >= 1 and pycor <= 9] [set pcolor 16]

  ;Bathroom2

  ask patches with [pxcor >= 10 and pxcor <= 16 and pycor = -5] [ set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor = 16 and pycor <= -3 and pycor >= -4] [ set pcolor gray set inside? false set wall? true]
  ask patches with [pxcor >= 16 and pxcor <= 24 and pycor = -3] [ set pcolor gray set inside? false set wall? true]

  ifelse(not NBR)
  [scenario-without-nbr]
  [nbr-doors-and-signals]

end

;; One Liners
to-report inside report patches with [inside?] end
to-report boards report patches with [board?] end
to-report exits  report patches with [exit?]   end
to-report frustrated? report (ticks - last-move) > 5 end
to go-to [a] face a move-to patch-ahead 1 set last-move ticks end
to swap [t] let p1 patch-here go-to t ask t [go-to p1] set swaps swaps + 1 end

;; Utilities
to flood-fill [pset]
  set pset patch-set pset
  ask patches [set flood 9999]
  ;paredes
  ask pset [set flood 0]
  while [count pset > 0]
  [ set pset patch-set [neighbors with [flood = 9999 and inside?]] of pset
    ask pset [set flood min [flood + distance myself] of neighbors] ]
end
@#$#@#$#@
GRAPHICS-WINDOW
216
26
723
554
35
35
7.0
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
10
25
73
58
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

SLIDER
11
142
206
175
population
population
1
2000
691
1
1
NIL
HORIZONTAL

BUTTON
77
26
140
59
NIL
go
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
144
26
207
59
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

MONITOR
107
456
207
501
Population
population
17
1
11

SLIDER
10
190
205
223
agent-size
agent-size
.25
3
1
.25
1
NIL
HORIZONTAL

CHOOSER
10
229
102
274
agent-shape
agent-shape
"circle" "person" "default"
1

SLIDER
11
106
205
139
obstacles
obstacles
0
200
15
1
1
NIL
HORIZONTAL

BUTTON
109
64
208
100
NIL
panic
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
6
456
101
501
People-out
people-out
17
1
11

SLIDER
9
279
205
312
scared-speed
scared-speed
0
7
5
1
1
NIL
HORIZONTAL

MONITOR
6
506
207
551
Scared People
scared-people
17
1
11

PLOT
8
568
237
758
People-In
ticks
inside
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range 0 population" ""
PENS
"default" 1.0 0 -16777216 true "" "if (scared-people > 0) [plot count turtles with [inside?]]"

PLOT
244
569
484
759
Scary
ticks
scared-people
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range 0 population" ""
PENS
"default" 1.0 0 -16777216 true "" "if (alarm-actived) and (scared-people != population) [plot scared-people]"

PLOT
488
569
727
758
People-Out
ticks
people-evacuated
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range 0 population" ""
PENS
"default" 1.0 0 -16777216 true "" "if (alarm-actived) and (scared-people = 1) [plot people-out]"

SWITCH
11
67
106
100
NBR
NBR
1
1
-1000

@#$#@#$#@
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
