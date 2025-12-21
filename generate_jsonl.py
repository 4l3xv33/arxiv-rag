import os
import time
import pickle
import urllib.parse
import feedparser
import requests
from datetime import datetime
import json


def main():
    query = {
        "query": '"Retrieval Augmented Generation"',
        "category": "cs.ai",
        "max_results": 5_000,
        "date_range": "[2025+TO+2025]",
        "sort_by": "submittedDate",
        "sort_order": "descending"
    }
    query_dict = encode_query_dict(query)
    entries = fetch_arxiv_results(query_dict)
    with open("corpus/corpus.jsonl", "w", encoding="utf-8") as f:
        for entry in entries:
            json.dump(entry, f, ensure_ascii=False)
            f.write("\n")
        print(f"\nSuccefully saved {len(entries)} entries to JSONL.")
    return

def encode_query_dict(query_dict: dict) -> dict:
    base_url = "http://export.arxiv.org/api/query?"
    search_query = f"all:{query_dict['query']}+AND+cat:{query_dict['category']}"
    search_query += f"+AND+submittedDate:" + query_dict['date_range']
    query_params = {
        "search_query": search_query,
        "sortBy": query_dict["sort_by"],
        "sortOrder": query_dict["sort_order"],
        "start": 0,
        "max_results": 100,
    }
    query_dict["query_params"] = query_params
    query_dict["base_url"] = base_url
    query_dict["url_encoded"] = base_url + urllib.parse.urlencode(query_params)
    return query_dict


def fetch_arxiv_results(query_dict: dict) -> list[dict]:
    all_entries = []
    max_total = query_dict["max_results"]
    page_size = query_dict["query_params"]["max_results"]
    for start in range(0, max_total, page_size):
        query_dict["query_params"]["start"] = start
        url = query_dict["base_url"] + urllib.parse.urlencode(
            query_dict["query_params"], safe=":+[]"
        )
        print(f"Preparing to fetch results {start} to {start + page_size}...")
        feed = feedparser.parse(url)
        if not feed.entries:
            print("No more entries found.")
            break
        all_entries.extend(feed.entries)
        print(feed.entries[-1])
        time.sleep(5)
    return all_entries


if __name__ == "__main__":
    main()