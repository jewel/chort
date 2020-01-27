# Chort, the Chore Chart

This is a browser-based chore tracker that I have built to keep track of my
children's chores.  It is synchronized in real time to any devices that have it
open.

## Why I built it

## How I use it

## Warnings

The database has been wiped out twice for me during testing.  Make backups.
I've also experienced a synchronization problem when stress-testing chore
toggling with multiple users.

## Installation Instructions

First, checkout this repository somewhere.  Then, from that directory, run:

Copy `client/config.coffee.example` to client/config.coffee` and edit to add
your children and their chores.

```bash
yarn install
nodemon server.js
```

Then browse to `http://localhost:3000`.

## Usage

### Keyboard Usage

### Points

## Note on licensing

## Hacking

The data and synchronization layer is built on top of statebus.  See
[its tutorial](https://braid.news/tutorial) for examples.

## Contributing

## TODO

- [ ] Basic authorization
- [ ] Get sounds with a compatible license
- [ ] Make better favicon
- [ ] Add screenshot to README
- [ ] Inline chore admin
- [ ] Emoji picker
