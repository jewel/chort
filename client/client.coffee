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


urlParams = new URLSearchParams window.location.search
secureMouse = urlParams.get("securemouse") == "1"

kids = chortConfig.kids
everyday = chortConfig.everyday
matrix = chortConfig.matrix
choreIcons = chortConfig.choreIcons
zones = chortConfig.zones

isSuper = () ->
  return false if !state.login || state.login < 3
  kid = kids[state.username]
  kid.super

checkMouse = (username) ->
  return true if !secureMouse
  return false if !state.login || state.login < 3
  return true if isSuper()
  state.username == username


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
logoutTime = 10000
logoutAt = null

logout = ->
  play 'stomp'
  state.login = 0
  logoutAt = null
  clearTimeout logoutTimer

updateLogoutRemaining = ->
  return null if logoutAt == null
  state.logoutRemaining = logoutAt - Date.now()
  if state.logoutRemaining < 0
    state.logoutRemaining = 0
  else
    requestAnimationFrame updateLogoutRemaining

resetLogoutTimer = ->
  clearTimeout logoutTimer
  logoutTimer = setTimeout logout, logoutTime
  logoutAt = Date.now() + logoutTime
  updateLogoutRemaining()

handleKey = (key) ->
  if key == "Enter"
    if state.login
      play 'kick'
      logout()
    else
      play '1-up'
      state.login = 1
      state.username = false
    return

  # Not logged in
  if state.login == 0
    if key == 'm'
      play '1-up'
    if key == 'n'
      play 'bowserfalls'
    if key == 'v'
      play 'bowserfire'
    if key == 'w'
      play 'breakblock'
    if key == 'k'
      play 'bump'
    if key == 'o'
      play 'coin'
    if key == 's'
      play 'fireball'
    if key == 'd'
      play 'fireworks'
    if key == 't'
      play 'flagpole'
    if key == 'q'
      play 'gameover'
    if key == 'y'
      play 'jump-small'
    if key == 'x'
      play 'jump-super'
    if key == 'p'
      play 'kick'
    if key == 'u'
      play 'mariodie'
    if key == 'z'
      play 'pause'
    if key == 'P'
      play 'pipe'
    if key == 'f'
      play 'powerup'
    if key == 'r'
      shortSounds = sounds.filter( (sound) -> buffers[sound].duration <= 1 )
      play shortSounds[ Math.floor( Math.random() * shortSounds.length ) ]
    return

  # Waiting for username (first letter)
  if state.login == 1
    Object.keys(kids).forEach (kid) ->
      if kid[0] == key
        state.login = 2
        state.username = kid
        state.password = ""
        play 'kick'
    return

  # Typing password
  if state.login == 2
    if key == "Backspace"
      state.password = state.password.slice 0, state.password.length - 1
      play 'kick'
      return
    if key.length == 1
      state.password += key
    if state.password == kids[state.username].password
      resetLogoutTimer()
      state.login = 3
      play 'coin'
    else if key.length == 1
      play 'kick'
    return

  # Logged in
  if state.login == 3
    num = parseInt key, 10
    if key == "0"
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
        if kid[0] == key
          changeStars kid, 1
          return
        if kid[0].toUpperCase() == key
          changeStars kid, -1
          return
      if key.length == 1
        play 'stomp'
    else
      play 'stomp'
    return

window.addEventListener "keydown", (e) ->
  handleKey e.key

dom.KEYPAD = ->
  return null unless secureMouse && state.login == 2
  DIV
    className: "keypad"
    dom.BUTTONS()
    BUTTON
      onClick: ->
        handleKey "Backspace"
      String.fromCharCode(9003)

dom.BUTTONS = ->
  [1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map (i) ->
    BUTTON
      onClick: ->
        handleKey "#{i}"

      "#{i}"


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
    text = "#{username} ready!"

  DIV
    className: "keyboard"
    color: "red"
    text
    dom.KEYPAD()
    dom.REMAINING()

dom.REMAINING = ->
  return null if logoutAt == null
  width = 800
  DIV
    className: "logout-remaining"
    style:
      width: width
    DIV
      className: "logout-remaining-bar"
      style:
        width: state.logoutRemaining / logoutTime * width

dom.MESSAGES = ->
  TEXTAREA
    className: "messages"
    value: state["/messages"]
    tabIndex: -1
    onChange: (e) -> state["/messages"] = e.target.value
    disabled: secureMouse

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
      if secureMouse
        handleKey "Enter"
      else
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
              if !secureMouse
                changeStars kid, 1
                broadcast 'coin'
              else
                state.login = 2
                state.username = kid
                state.password = ""
                play 'kick'
          DIV
            className: "kid-stars"
            border: "10px solid #{kids[kid].color}"
            onClick: ->
              if !secureMouse
                changeStars kid, -1
                broadcast 'stomp'
            starTotal kid
          if secureMouse && isSuper()
            [
              DIV
                className: "kid-stars-button kid-stars-down"
                border: "10px solid #{kids[kid].color}"
                key: 'stars-down'
                onClick: ->
                  resetLogoutTimer()
                  changeStars kid, -1
                  broadcast 'stomp'
                '-'
              DIV
                className: "kid-stars-button kid-stars-up"
                border: "10px solid #{kids[kid].color}"
                key: 'stars-up'
                onClick: ->
                  resetLogoutTimer()
                  changeStars kid, 1
                  broadcast 'stomp'
                '+'
            ]

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
              if checkMouse(kid)
                resetLogoutTimer()
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

