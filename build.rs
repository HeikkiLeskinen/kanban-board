use std::process::Command;

fn main() {
    let exitcode = Command::new("elm")
        .args(&["make", "gui/Main.elm", "--output=elm.js"])
        .status()
        .unwrap();

    assert!(exitcode.success());
}