// Kindle clippings file parser

use anyhow::Result;
use chrono::{DateTime, NaiveDateTime, Utc};
use once_cell::sync::Lazy;
use regex::Regex;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

/// Parsed highlight from Kindle clippings file
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParsedHighlight {
    pub book_title: String,
    pub author: Option<String>,
    pub content: String,
    pub highlight_type: HighlightType,
    pub location: Option<String>,
    pub page: Option<i32>,
    pub kindle_date: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum HighlightType {
    Highlight,
    Note,
    Bookmark,
}

/// Parse Kindle clippings file content
pub fn parse_clippings(content: &str) -> Result<Vec<ParsedHighlight>> {
    let mut highlights = Vec::new();

    // Split by separator (==========)
    let entries: Vec<&str> = content.split("==========").collect();

    for entry in entries {
        let entry = entry.trim();
        if entry.is_empty() {
            continue;
        }

        if let Some(highlight) = parse_single_entry(entry) {
            highlights.push(highlight);
        }
    }

    Ok(highlights)
}

fn parse_single_entry(entry: &str) -> Option<ParsedHighlight> {
    let lines: Vec<&str> = entry.lines().collect();

    if lines.len() < 3 {
        return None;
    }

    // Line 1: Book title (Author)
    let (title, author) = parse_title_line(lines[0]);

    // Line 2: Metadata (type, location, page, date)
    let (highlight_type, location, page, kindle_date) = parse_metadata_line(lines[1]);

    // Line 3+: Content (skip empty line after metadata)
    let content_start = if lines.get(2).map(|s| s.is_empty()).unwrap_or(false) { 3 } else { 2 };
    let content: String = lines[content_start..].join("\n").trim().to_string();

    if content.is_empty() {
        return None;
    }

    Some(ParsedHighlight {
        book_title: title,
        author,
        content,
        highlight_type,
        location,
        page,
        kindle_date,
    })
}

fn parse_title_line(line: &str) -> (String, Option<String>) {
    // Format: "Book Title (Author Name)"
    if let Some(paren_start) = line.rfind('(') {
        if let Some(paren_end) = line.rfind(')') {
            let title = line[..paren_start].trim().to_string();
            let author = line[paren_start + 1..paren_end].trim().to_string();
            return (title, Some(author));
        }
    }
    (line.trim().to_string(), None)
}

fn parse_metadata_line(line: &str) -> (HighlightType, Option<String>, Option<i32>, Option<DateTime<Utc>>) {
    let highlight_type = if line.contains("Note") {
        HighlightType::Note
    } else {
        HighlightType::Highlight
    };

    // Extract location
    let location = extract_pattern(line, "Location ", " |")
        .or_else(|| extract_pattern(line, "Location ", "\n"));

    // Extract page
    let page = extract_pattern(line, "page ", " |")
        .or_else(|| extract_pattern(line, "page ", "\n"))
        .and_then(|s| s.parse().ok());

    // TODO: Parse date (format varies by Kindle language settings)
    let kindle_date = None;

    (highlight_type, location, page, kindle_date)
}

fn extract_pattern(text: &str, start: &str, end: &str) -> Option<String> {
    let start_idx = text.find(start)?;
    let value_start = start_idx + start.len();
    let remaining = &text[value_start..];
    let end_idx = remaining.find(end).unwrap_or(remaining.len());
    Some(remaining[..end_idx].trim().to_string())
}

// ============================================
// Regex patterns for robust parsing
// ============================================

/// Regex patterns for parsing Kindle clippings
pub mod patterns {
    use super::*;

    /// Pattern for title with author: "Book Title (Author Name)"
    pub static TITLE_AUTHOR: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r"^(.+?)\s*\(([^)]+)\)\s*$").expect("Invalid title regex")
    });

    /// Pattern for highlight/note type
    pub static ENTRY_TYPE: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r"Your (Highlight|Note|Bookmark)").expect("Invalid type regex")
    });

    /// Pattern for page number
    pub static PAGE_NUMBER: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r"page\s+(\d+)").expect("Invalid page regex")
    });

    /// Pattern for location
    pub static LOCATION: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r"Location\s+([\d\-]+)").expect("Invalid location regex")
    });

    /// US date format: "Monday, January 15, 2024 12:30:45 PM"
    pub static DATE_US: Lazy<Regex> = Lazy::new(|| {
        Regex::new(
            r"Added on \w+,\s+(\w+)\s+(\d{1,2}),\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s*(AM|PM)"
        ).expect("Invalid US date regex")
    });

    /// UK date format: "Monday, 15 January 2024 12:30:45"
    pub static DATE_UK: Lazy<Regex> = Lazy::new(|| {
        Regex::new(
            r"Added on \w+,\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})"
        ).expect("Invalid UK date regex")
    });

    /// Parse title and author using regex
    pub fn parse_title_regex(line: &str) -> (String, Option<String>) {
        if let Some(captures) = TITLE_AUTHOR.captures(line) {
            let title = captures.get(1).map(|m| m.as_str().trim().to_string()).unwrap_or_default();
            let author = captures.get(2).map(|m| m.as_str().trim().to_string());
            return (title, author);
        }
        (line.trim().to_string(), None)
    }

    /// Parse highlight type from metadata line
    pub fn parse_type_regex(line: &str) -> HighlightType {
        if let Some(captures) = ENTRY_TYPE.captures(line) {
            match captures.get(1).map(|m| m.as_str()) {
                Some("Note") => return HighlightType::Note,
                Some("Bookmark") => return HighlightType::Bookmark,
                _ => return HighlightType::Highlight,
            }
        }
        HighlightType::Highlight
    }

    /// Parse page number from metadata line
    pub fn parse_page_regex(line: &str) -> Option<i32> {
        PAGE_NUMBER.captures(line)
            .and_then(|c| c.get(1))
            .and_then(|m| m.as_str().parse().ok())
    }

    /// Parse location from metadata line
    pub fn parse_location_regex(line: &str) -> Option<String> {
        LOCATION.captures(line)
            .and_then(|c| c.get(1))
            .map(|m| m.as_str().to_string())
    }

    /// Parse date from metadata line (handles US and UK formats)
    pub fn parse_date_regex(line: &str) -> Option<DateTime<Utc>> {
        // Try US format first
        if let Some(captures) = DATE_US.captures(line) {
            return parse_us_date(&captures);
        }
        // Try UK format
        if let Some(captures) = DATE_UK.captures(line) {
            return parse_uk_date(&captures);
        }
        None
    }

    fn parse_us_date(captures: &regex::Captures) -> Option<DateTime<Utc>> {
        let month_str = captures.get(1)?.as_str();
        let day: u32 = captures.get(2)?.as_str().parse().ok()?;
        let year: i32 = captures.get(3)?.as_str().parse().ok()?;
        let mut hour: u32 = captures.get(4)?.as_str().parse().ok()?;
        let minute: u32 = captures.get(5)?.as_str().parse().ok()?;
        let second: u32 = captures.get(6)?.as_str().parse().ok()?;
        let am_pm = captures.get(7)?.as_str();

        // Convert to 24-hour format
        if am_pm == "PM" && hour != 12 {
            hour += 12;
        } else if am_pm == "AM" && hour == 12 {
            hour = 0;
        }

        let month = month_to_number(month_str)?;
        let naive = NaiveDateTime::parse_from_str(
            &format!("{:04}-{:02}-{:02} {:02}:{:02}:{:02}", year, month, day, hour, minute, second),
            "%Y-%m-%d %H:%M:%S"
        ).ok()?;

        Some(DateTime::from_naive_utc_and_offset(naive, Utc))
    }

    fn parse_uk_date(captures: &regex::Captures) -> Option<DateTime<Utc>> {
        let day: u32 = captures.get(1)?.as_str().parse().ok()?;
        let month_str = captures.get(2)?.as_str();
        let year: i32 = captures.get(3)?.as_str().parse().ok()?;
        let hour: u32 = captures.get(4)?.as_str().parse().ok()?;
        let minute: u32 = captures.get(5)?.as_str().parse().ok()?;
        let second: u32 = captures.get(6)?.as_str().parse().ok()?;

        let month = month_to_number(month_str)?;
        let naive = NaiveDateTime::parse_from_str(
            &format!("{:04}-{:02}-{:02} {:02}:{:02}:{:02}", year, month, day, hour, minute, second),
            "%Y-%m-%d %H:%M:%S"
        ).ok()?;

        Some(DateTime::from_naive_utc_and_offset(naive, Utc))
    }

    fn month_to_number(month: &str) -> Option<u32> {
        match month.to_lowercase().as_str() {
            "january" | "jan" => Some(1),
            "february" | "feb" => Some(2),
            "march" | "mar" => Some(3),
            "april" | "apr" => Some(4),
            "may" => Some(5),
            "june" | "jun" => Some(6),
            "july" | "jul" => Some(7),
            "august" | "aug" => Some(8),
            "september" | "sep" => Some(9),
            "october" | "oct" => Some(10),
            "november" | "nov" => Some(11),
            "december" | "dec" => Some(12),
            _ => None,
        }
    }
}

/// Generate SHA-256 content hash for duplicate detection
pub fn generate_content_hash(book_title: &str, content: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(book_title.as_bytes());
    hasher.update(content.as_bytes());
    hex::encode(hasher.finalize())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_title_with_author() {
        let (title, author) = parse_title_line("The Great Gatsby (F. Scott Fitzgerald)");
        assert_eq!(title, "The Great Gatsby");
        assert_eq!(author, Some("F. Scott Fitzgerald".to_string()));
    }

    #[test]
    fn test_parse_title_without_author() {
        let (title, author) = parse_title_line("Unknown Book");
        assert_eq!(title, "Unknown Book");
        assert_eq!(author, None);
    }

    #[test]
    fn test_parse_clippings() {
        let content = r#"The Great Gatsby (F. Scott Fitzgerald)
- Your Highlight on page 5 | Location 72-75 | Added on Monday, January 20, 2026 10:30:00 AM

In my younger and more vulnerable years my father gave me some advice.
==========
1984 (George Orwell)
- Your Note on page 50 | Location 750 | Added on Tuesday, January 21, 2026 9:30:00 AM

This reminds me of modern surveillance.
=========="#;

        let highlights = parse_clippings(content).unwrap();
        assert_eq!(highlights.len(), 2);
        assert_eq!(highlights[0].book_title, "The Great Gatsby");
        assert_eq!(highlights[0].highlight_type, HighlightType::Highlight);
        assert_eq!(highlights[1].book_title, "1984");
        assert_eq!(highlights[1].highlight_type, HighlightType::Note);
    }
}
