#[macro_use]
extern crate serde_derive;
extern crate serde_json;
extern crate web_view;
extern crate open;

use std::fs;
use std::fs::File;
use std::io::prelude::*;
use std::time::{SystemTime, UNIX_EPOCH};

static CACHE_FILENAME: &'static str = env!("TASK_FILE_PATH", "You forgot to export TASK_FILE_PATH path");
const ONE_DAY_IN_SECONDS: u64 = 86400;

pub struct Cache<T> {
    data: Box<Vec<T>>,
}

impl<T> Cache<T> {
    pub fn new() -> Cache<T> {
        Cache {
            data: Box::new(vec![]),
        }
    }

    pub fn get_data_from_storage(&self) -> String {
        let mut file = match File::open(CACHE_FILENAME) {
            Ok(file) => file,
            Err(_) => {
                self.write(String::from(""));
                File::open(CACHE_FILENAME).expect("could not initialize cache")
            }
        };

        let mut contents = String::new();
        file.read_to_string(&mut contents)
            .expect("something went wrong reading the file");

        contents
    }

    pub fn set_data(&mut self, data: Box<Vec<T>>) {
        self.data = data;
    }

    pub fn write(&self, data: String) {
        fs::write(CACHE_FILENAME, data).expect("could not write to cache");
    }
}

impl Cache<Task> {
    pub fn initialize(&mut self) {
        let data = self.get_data_from_storage();

        // return a new vec if our cache is improper
        let tasks: Box<Vec<Task>> = match serde_json::from_str(&data) {
            Ok(data) => data,
            Err(_) => Box::new(vec![]),
        };

        self.set_data(tasks);
    }

    pub fn get_tasks(&mut self) -> Vec<Task> {
        let tasks = &self.data.clone();
        
        let current_epoch = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("Could not calculate epoch server")
            .as_secs();
       
        let mut active_tasks = vec![];

        for mut task in tasks.iter().cloned() {
                        
            if task.status == "Done" && current_epoch - task.updated > ONE_DAY_IN_SECONDS {                
                continue;
            }
            
            if let Some(w) = &task.wait_until  {
                if task.status == "Snooze" && current_epoch > *w {
                    task.status = "InProgress".to_string();
                    task.wait_until = None::<u64>;
                }
            }

            active_tasks.push(task);
        }
            
        active_tasks
    }

    pub fn serialize(&self) -> String {
        serde_json::to_string(&self.data).unwrap()
    }

    pub fn store_tasks(&mut self, tasks: &Vec<Task>) {
        self.set_data(Box::new(tasks.to_vec()));
        self.write(self.serialize());
    }

}

#[derive(Deserialize, Serialize, Debug, Eq, Ord, PartialEq, PartialOrd, Clone)]
pub struct Task {
    subject: String,
    status: String,
    priority: i32,
    wait_until: Option<u64>,
    updated: u64,
}
