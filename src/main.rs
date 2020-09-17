#[macro_use]
extern crate serde_derive;
extern crate serde_json;
extern crate web_view;
extern crate lib;

use web_view::*;
use lib::*;

fn main() {
    let mut cache: Cache<Task> = Cache::new();
    cache.initialize();

    let webview = web_view::builder()
        .title("Kanban for Managers")
        .content(Content::Html(create_html()))
        .size(800, 600)
        .resizable(true)
        .debug(false)
        .user_data(())
        .invoke_handler(|_webview, _arg| {
            use Action::*;

            let result = serde_json::from_str(_arg).unwrap_or_else(|e| {
                println!("invalid arguments: {}", _arg.to_string()); 
                panic!(e);
            });

            match result {
                Init => {
                    send_response(
                        _webview,
                        &Response::Tasks {
                            tasks: cache.get_tasks()
                        },
                    );
                }
                Log { text } => { 
                    println!("{}", text) 
                }
                StoreTasks { tasks } => {
                    cache.store_tasks(&tasks);

                    send_response(
                        _webview,
                        &Response::Tasks {
                            tasks: cache.get_tasks(),
                        },
                    );
                }                
            }            
            Ok(())
        }).build()
        .unwrap();

    webview.run().unwrap();
}

#[derive(Deserialize)]
#[serde(tag = "cmd")]
pub enum Action {
    Init,
    Log { text: String },
    StoreTasks { tasks: Vec<Task> },
}

#[derive(Serialize, Debug)]
#[serde(tag = "data")]
pub enum Response {
    Tasks { tasks: Vec<Task> },    
    Error { error: String },
}

pub fn send_response<'a, S, T>(webview: &mut WebView<'a, T>, data: &S)
where
    S: serde::ser::Serialize,
{
    match serde_json::to_string(data) {
        Ok(json) => match webview.eval(&format!("sendResponse({})", json)) {
            Ok(_) => (),
            Err(error) => println!("failed to send to ui because {}", error),
        },
        Err(error) => println!("failed to serialize for ui because {}", error),
    };
}

fn create_html() -> String {
    format!(r#"
        <html>
            <head>
            <link href="https://fonts.googleapis.com/css?family=PT+Sans" rel="stylesheet">
            <style>{css}</style>
            {styles}
            </head>
            <body>
                <div id="app"></div>
                {scripts}
            </body>
        </html>
    "#,
        css = r#"body { background: #1d1f21; }"#,
        scripts = inline_script(include_str!("../elm.js")) 
              + &inline_script(include_str!("../app.js")),
        styles = inline_style(include_str!("../gui/main.css")),
    )
}

fn inline_style(s: &str) -> String {
    format!(r#"<style type="text/css">{}</style>"#, s)
}

fn inline_script(s: &str) -> String {
    format!(r#"<script type="text/javascript">{}</script>"#, s)
}
