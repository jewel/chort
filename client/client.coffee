context = new AudioContext()
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
    "coin"
    "stomp"
    "warning"
    "mariodie"
    "1-up"
  ]

sounds.forEach (key) ->
  loadSound key

broadcast = (key) ->
  state['/sound/next'] = key
  state['/sound/counter'] = (state['/sound/counter'] || 0) + 1

play = (key) ->
  buffer = buffers[key]
  source = context.createBufferSource()
  source.buffer = buffer
  source.connect context.destination
  source.start 0

kids = chortConfig.kids
everyday = chortConfig.everyday
matrix = chortConfig.matrix
choreIcons = chortConfig.choreIcons

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
      state.login = 1
      state.username = false
    return

  if state.login == 0
    if e.key == 'm'
      play 'mariodie'
    if e.key == 'n'
      play 'warning'
    return

  if state.login == 1
    Object.keys(kids).forEach (kid) ->
      if kid[0] == e.key
        state.login = 2
        state.username = kid
        state.password = ""
    return

  if state.login == 2
    state.password += e.key
    if state.password == kids[state.username].password
      resetLogoutTimer()
      state.login = 3
      play 'coin'
    return

  if state.login == 3
    num = parseInt e.key, 10
    resetLogoutTimer()
    if num > 0
      list = kidChores state.username
      chore = list[num - 1]
      if choreIcons[chore]
        toggleChore state.username, chore
      else
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
  d = date()
  str = ""
  str += d.getFullYear()
  str += "-"
  str += two(d.getMonth() + 1)
  str += "-"
  str += two d.getDate()
  str

toggleChore = (kid, chore) ->
  key = "/#{today()}/#{kid}/#{chore}"
  if state[key]
    broadcast 'stomp'
  else
    broadcast '1-up'
  state[key] = !state[key]

kidChores = (kid) ->
  everyday[kid].concat(matrix[kid][date().getDay()] || [])

dom.CHORE_CHART = ->
  DIV {className: "chore-chart"},
    key: "chore-chart"
    Object.keys(kids).map (kid) ->
      DIV
        className: "kid"
        key: kid
        DIV
          className: "kid-picture-container"
          IMG
            className: "kid-picture"
            src: kids[kid].picture
            backgroundColor: kids[kid].color
            onClick: ->
              state["/stars/#{kid}"] = (state["/stars/#{kid}"] || 0) + 1
              broadcast 'coin'
          DIV
            className: "kid-stars"
            border: "10px solid #{kids[kid].color}"
            onClick: ->
              state["/stars/#{kid}"] = (state["/stars/#{kid}"] || 0) - 1
              broadcast 'stomp'
            "" + (state["/stars/#{kid}"] || 0)
        kidChores(kid).map (chore) ->
          key = "/#{today()}/#{kid}/#{chore}"
          done = state[key]
          DIV
            key: chore
            className: "chore"
            backgroundColor: if done then kids[kid].color else "black"
            opacity: if done then "1.0" else "0.5"
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

