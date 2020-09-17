## Kanban Board

![Kanban Board](screenshot.png)

A simple cross-platform local kanban board, implemented with Rust web-view and Elm. 
This simple application is like a extended todo list, which allows you to control your daily work.

## Table of Contents

* [About the Project](#about-the-project)
  * [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
* [Usage](#usage)
* [License](#license)
* [Contact](#contact)
* [Acknowledgements](#acknowledgements)

### Built With
Implemented with Rust and Elm.
* [Elm](https://getbootstrap.com)
* [Rust](https://jquery.com)

## Getting Started

### Prerequisites

This is an example of how to list things you need to use the software and how to install them.

**Git**
```shell
https://www.atlassian.com/git/tutorials/install-git
```

**Elm**
```shell
https://guide.elm-lang.org/install/elm.html
```

**Rust**
```shell
https://www.rust-lang.org/tools/install
cargo install cargo-bundle
```

### Installation

**Clone the git repository**
```shell
git clone https://github.com/HeikkiLeskinen/kanban-board/
```

**Build the cargo project and release**
```shell
export KANBAN_TASK_DIR="<path>/cache.json"; cargo build
cargo run # run & test
cargo bundle --release
```

## Usage

* Task older than 24-hours in a Done column are removed
* Snoozed tasks are returned to in-progress column after 1 hour 

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

Heikki Leskinen - [@heikki4real](https://twitter.com/heikki4real) - heikki.leskinen@gmail.com

## Acknowledgements
* [Desktop Kanban Board](https://github.com/huytd/kanban-app)
* [Kanelm - Kanban Board in Elm](https://github.com/huytd/kanelm)


