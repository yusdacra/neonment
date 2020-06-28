[![Matrix](https://img.shields.io/matrix/neonment:matrix.org?label=General%20Chat&style=flat-square)](https://matrix.to/#/!bvDgjKjhEDWtYXoeXn:matrix.org?via=feneas.org&via=matrix.org)
[![Matrix](https://img.shields.io/matrix/neonment-dev:matrix.org?label=Dev%20Chat&style=flat-square)](https://matrix.to/#/!iBcMbYbiTGUBxLqqlJ:matrix.org?via=feneas.org&via=matrix.org&via=t2bot.io)

# Neonment
A first person hero shooter that features lots of neon lights. The name may change in the future.

## Running
- For client:
    - Get a debug build from the latest pipeline artifacts, and uncompress it.
        - [Linux](https://gitlab.com/yusdacra/neonment/-/jobs/artifacts/master/download?job=linux-client)
            - You need to run `chmod +x NeonmentClient.x86_64` to make the game executable.
        - [Windows](https://gitlab.com/yusdacra/neonment/-/jobs/artifacts/master/download?job=windows-client)
        - [Mac OS](https://gitlab.com/yusdacra/neonment/-/jobs/artifacts/master/download?job=mac-client)
    - Or:
        - Get [Godot](https://godotengine.org/download)
        - Clone the project (Or download a specific commit / tag)
        - Open your terminal and from the root of the project, run `path/to/godot common/main.tscn`
- For server:
    - Get [Godot server binary](https://godotengine.org/download/server) (only for Linux)
    - Clone the project (Or download a specific commit / tag)
    - Open your terminal and from the root of the project, run `path/to/godot-server common/main.tscn`

## Development setup
- Install [Godot](https://godotengine.org/download)
- Clone the project
- Import the project
