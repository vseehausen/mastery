// Kindle USB detection and file reading module

pub mod detection;
pub mod mount;
pub mod parser;
#[cfg(test)]
mod tests;
pub mod watcher;

pub use detection::*;
pub use mount::*;
pub use parser::*;
pub use watcher::*;
