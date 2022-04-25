context = new AudioContext()
gain = context.createGain()
gain.connect context.destination
gain.gain.value = 0.4

buffers = {}

createSoundSource = (key, data) ->
  context.decodeAudioData data, (buffer) ->
    buffers[key] = buffer

loadSound = (key) ->
  req = new XMLHttpRequest()
  req.open "GET", "/audio/#{key}.wav", true
  req.responseType = 'arraybuffer'

  req.onload = ->
    data = req.response
    createSoundSource key, data

  req.send()

sounds = [
    "1-up"
    "bowserfalls"
    "bowserfire"
    "breakblock"
    "bump"
    "coin"
    "fireball"
    "fireworks"
    "flagpole"
    "gameover"
    "jump-small"
    "jump-super"
    "kick"
    "mariodie"
    "pause"
    "pipe"
    "powerup"
    "powerup_appears"
    "stage_clear"
    "stomp"
    "underworld"
    "vine"
    "warning"
    "world_clear"
  ]

sounds.forEach (key) ->
  loadSound key

broadcast = (key) ->
  state['/sound/next'] = key
  state['/sound/counter'] = (state['/sound/counter'] || 0) + 1

playing = false

play = (key) ->
  if playing
    return
  buffer = buffers[key]
  source = context.createBufferSource()
  source.buffer = buffer
  source.connect gain
  source.start 0
  setTimeout (-> playing = false), buffer.duration * 1000
  playing = true


kids = chortConfig.kids
everyday = chortConfig.everyday
matrix = chortConfig.matrix
choreIcons = chortConfig.choreIcons
zones = chortConfig.zones

daysOfWeek = [
    "Sun"
    "Mon"
    "Tue"
    "Wed"
    "Thu"
    "Fri"
    "Sat"
  ]

ordinal_suffix = (i) ->
  j = i % 10
  k = i % 100
  if j == 1 && k != 11
    "st"
  else if j == 2 && k != 12
    "nd"
  else if j == 3 && k != 13
    "rd"
  else
    "th"

timeouts = {}

registerTime = ->
  bus("time/*").to_fetch = (key, star, t) ->
    interval = if star.length then parseInt(star, 10) else 1
    f = ->
      t.return key: key, time: Date.now()
    timeouts[key] = setInterval f, interval * 1000
    f()

  bus("time/*").to_forget = (key) ->
    clearTimeout timeouts[key]

window.statebus_ready = window['statebus_ready'] || []
statebus_ready.push registerTime

logoutTimer = null

logout = ->
  play 'stomp'
  state.login = 0
  clearTimeout logoutTimer

resetLogoutTimer = ->
  clearTimeout logoutTimer
  logoutTimer = setTimeout logout, 10000

window.addEventListener "keydown", (e) ->
  if e.key == "Enter"
    if state.login
      logout()
    else
      play '1-up'
      state.login = 1
      state.username = false
    return

  # Not logged in
  if state.login == 0
    if e.key == 'm'
      play '1-up'
    if e.key == 'n'
      play 'bowserfalls'
    if e.key == 'v'
      play 'bowserfire'
    if e.key == 'w'
      play 'breakblock'
    if e.key == 'k'
      play 'bump'    
    if e.key == 'o'
      play 'coin'
    if e.key == 's'
      play 'fireball'  
    if e.key == 'd'
      play 'fireworks'
    if e.key == 't'
      play 'flagpole'
    if e.key == 'q'
      play 'gameover'
    if e.key == 'y'
      play 'jump-small'
    if e.key == 'x'
      play 'jump-super'
    if e.key == 'p'
      play 'kick'
    if e.key == 'u'
      play 'mariodie'
    if e.key == 'z'
      play 'pause'
    if e.key == 'P'
      play 'pipe'
    if e.key == 'f'
      play 'powerup'
    if e.key == 'r'
      shortSounds = sounds.filter( (sound) -> buffers[sound].duration <= 1 )
      play shortSounds[ Math.floor( Math.random() * shortSounds.length ) ]
    return

  # Waiting for username (first letter)
  if state.login == 1
    Object.keys(kids).forEach (kid) ->
      if kid[0] == e.key
        state.login = 2
        state.username = kid
        state.password = ""
    return

  # Typing password
  if state.login == 2
    if e.key == "Backspace"
      state.password = state.password.slice 0, state.password.length - 1
      return
    if e.key.length == 1
      state.password += e.key
    if state.password == kids[state.username].password
      resetLogoutTimer()
      state.login = 3
      play 'coin'
    return

  # Logged in
  if state.login == 3
    num = parseInt e.key, 10
    if e.key == "0"
      num = 10
    resetLogoutTimer()
    if num > 0
      list = kidChores state.username
      chore = list[num - 1]
      if choreIcons[chore]
        toggleChore state.username, chore
      else
        play 'stomp'
    else if kids[state.username].super
      Object.keys(kids).forEach (kid) ->
        if kid[0] == e.key
          changeStars kid, 1
          return
        if kid[0].toUpperCase() == e.key
          changeStars kid, -1
          return
      if e.key.length == 1
        play 'stomp'
    else
      play 'stomp'
    return

dom.KEYBOARD = ->
  text = ""
  username = state.username
  password = state.password
  if state.login == 1
    text = "login: "
  if state.login == 2
    text = "#{username} password: "
    for i in [0...password.length]
      text += "*"
  if state.login == 3
    text = "#{username} ready! "

  DIV
    className: "keyboard"
    color: "red"
    text

dom.MESSAGES = ->
  TEXTAREA
    className: "messages"
    value: state["/messages"]
    tabIndex: -1
    onChange: (e) -> state["/messages"] = e.target.value

two = (i) ->
  i.toString().padStart 2, '0'

lastRefresh = 0

refresh = -> location.reload()

dom.CLOCK = ->
  time = new Date(state["time/1"].time)

  if state["/refresh"] > 0 && lastRefresh > 0 && state["/refresh"] != lastRefresh
    setTimeout refresh, 1000

  lastRefresh = state["/refresh"]

  DIV {className: "clock"},
    key: "clock"
    backgroundColor: "hsl(#{360 / (24 * 60) * time.getHours() * 60 +  time.getMinutes()}, 88%, 60%)"
    onClick: ->
      state["/refresh"] = (state["/refresh"] || 0) + 1
    DIV {className: "time"},
      two time.getHours()
      ":"
      two time.getMinutes()
    DIV {className: "date"},
      "#{daysOfWeek[time.getDay()]} "
      "#{time.getDate()}"
      SUP "#{ordinal_suffix time.getDate()}"

date = ->
  new Date(state["time/3600"].time)

today = ->
  isoDate date()

isoDate = ( d ) ->
  str = ""
  str += d.getFullYear()
  str += "-"
  str += two(d.getMonth() + 1)
  str += "-"
  str += two d.getDate()
  str

toggleChore = (kid, chore) ->
  key = "/#{today()}/#{kid}/#{chore}"
  state[key] = !state[key]

  if state[key]
    if allDone(kid)
      broadcast 'world_clear'
    else
      broadcast '1-up'
  else
    broadcast 'stomp'

starDiffKey = (kid) ->
  key = "/stars_diff/#{today()}/#{kid}"

changeStars = (kid, diff) ->
  key = starDiffKey kid
  state[key] = 0 unless state[key]
  state[key] += diff
  state["/stars/#{kid}"] = (state["/stars/#{kid}"] || 0) + diff

starTotal = (kid) ->
  total = state["/stars/#{kid}"] || 0
  diff = state[starDiffKey(kid)] || 0
  str = "#{total - diff}"
  if diff > 0
    str += "+#{diff}"
  else if diff < 0
    str += "-#{-diff}"
  str

todaysZones = (kid) ->
  days = Math.round( (Date.parse(today()) - Date.parse(zones.start)) / (24 * 60 * 60 * 1000))
  weeks = Math.floor(days / 7)
  index = zones.owners.indexOf( kid )
  return [] if index == -1
  offset = (weeks + index) % zones.rotation.length
  [zones.rotation[offset]]


kidChores = (kid) ->
  (everyday[kid] || []).concat(todaysZones(kid)).concat((matrix[kid] || [])[date().getDay()] || [])

allDone = (kid) ->
  for chore in kidChores(kid)
    if !state["/#{today()}/#{kid}/#{chore}"]
      return false
  true

dom.CHORE_CHART = ->
  DIV
    className: 'chore-chart'
    Object.keys(kids).map (kid) ->
      return null if kids[kid].invisible
      DIV
        className: "kid"
        key: kid
        DIV
          className: "kid-picture-container"
          IMG
            className: "kid-picture"
            src: kids[kid].picture
            backgroundColor: kids[kid].color
            boxShadow: if allDone(kid) then "0 0 80px #{kids[kid].color}" else "none"
            onClick: ->
              changeStars kid, 1
              broadcast 'coin'
          DIV
            className: "kid-stars"
            border: "10px solid #{kids[kid].color}"
            onClick: ->
              changeStars kid, -1
              broadcast 'stomp'
            starTotal kid
        kidChores(kid).map (chore) ->
          key = "/#{today()}/#{kid}/#{chore}"
          done = state[key]
          DIV
            key: chore
            className: "chore"
            backgroundColor: if done then kids[kid].color else "black"
            opacity: if done then "1.0" else "0.5"
            title: chore
            onClick: ->
              toggleChore kid, chore
            IMG
              key: "chore-picture"
              src: "/emoji/emoji_u#{choreIcons[chore]}.svg"
              alt: chore

lastSound = 0
dom.SOUND = ->
  if state["/sound/counter"] > 0 && lastSound > 0 && state["/sound/counter"] != lastSound
    play state["/sound/next"]
  lastSound = state["/sound/counter"]
  DIV

dom.BODY = ->
  DIV
    key: 'container'
    className: 'container'
    MESSAGES()
    CLOCK()
    CHORE_CHART()
    KEYBOARD()
    SOUND()

