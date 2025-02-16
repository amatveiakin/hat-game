use clap::Parser;
use itertools::Itertools;
use serde::de::Deserialize;
use std::collections::HashSet;
use std::fs::File;
use std::io::Read;

#[derive(Debug, Parser)]
#[command(version)]
struct Args {
    lexicon: String,
}

fn read_lexicon(lexicon_path: &str) -> Vec<String> {
    let mut file = File::open(lexicon_path).expect("Failed to open lexicon file");
    let mut content = String::new();
    file.read_to_string(&mut content)
        .expect("Failed to read lexicon file");

    let documents = serde_yaml::Deserializer::from_str(&content);
    let mut documents = documents.into_iter();
    documents.next(); // skip first document
    let word_list: Vec<String> =
        serde_yaml::from_value(serde_yaml::Value::deserialize(documents.next().unwrap()).unwrap())
            .unwrap();

    word_list
}

fn split_phrase(word_set: &HashSet<String>, chars: &[char], phrase: &mut String) -> bool {
    if chars.is_empty() {
        return true;
    }
    let mut prefix = String::new();
    for i in 0..chars.len() {
        prefix.push(chars[i]);
        if word_set.contains(&prefix) {
            let orig_phrase_len = phrase.len();
            assert!(!phrase.is_empty());
            phrase.push(' ');
            phrase.push_str(&prefix);
            if split_phrase(word_set, &chars[i + 1..], phrase) {
                return true;
            }
            phrase.truncate(orig_phrase_len);
        }
    }
    false
}

fn fill_palindromes(
    word_list: &[String],
    word_set: &HashSet<String>,
    target_len: usize,
    candidate_chars: &mut Vec<char>,
    candidate_phrase: &mut String,
    palindromes: &mut Vec<String>,
) {
    let orig_len = candidate_chars.len();
    if orig_len * 2 >= target_len {
        for i in ((target_len + 1) / 2)..target_len {
            let j = target_len - i - 1;
            if i < orig_len {
                if candidate_chars[i] != candidate_chars[j] {
                    return;
                }
            } else {
                candidate_chars.push(candidate_chars[j]);
            }
        }
        if split_phrase(word_set, &candidate_chars[orig_len..], candidate_phrase) {
            palindromes.push(candidate_phrase.clone());
        }
    } else {
        for word in word_list {
            if word.len() + orig_len <= target_len {
                let orig_phrase_len = candidate_phrase.len();
                if !candidate_phrase.is_empty() {
                    candidate_phrase.push(' ');
                }
                candidate_chars.extend(word.chars());
                candidate_phrase.push_str(word);
                fill_palindromes(
                    word_list,
                    word_set,
                    target_len,
                    candidate_chars,
                    candidate_phrase,
                    palindromes,
                );
                candidate_chars.truncate(orig_len);
                candidate_phrase.truncate(orig_phrase_len);
            }
        }
    }
}

fn main() {
    let args = Args::parse();
    let word_list = read_lexicon(&args.lexicon);
    let word_set: HashSet<String> = word_list.iter().cloned().collect();
    let target_len = 15;
    let mut palindromes = Vec::new();
    let mut candidate = Vec::new();
    let mut candidate_phrase = String::new();
    fill_palindromes(
        &word_list,
        &word_set,
        target_len,
        &mut candidate,
        &mut candidate_phrase,
        &mut palindromes,
    );
    println!("{}", palindromes.iter().filter(|p| p.chars().count() <= target_len + 2).join("\n"));
}
