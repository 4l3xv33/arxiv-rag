import time
import json
import urllib.parse
import feedparser
import requests


def main():
    query = {
        "query_text": "Retrieval Augmented Generation",
        "category": "cs.ai",
        "max_results": 5_000,
        "date_range": "[2025+TO+2025]",
        "sort_by": "submittedDate",
        "sort_order": "descending",
        "page_size": 100,
    }

    q = build_query(query)
    entries = fetch_arxiv_results(q)

    write_jsonl_and_ndjson(
        entries=entries,
        jsonl_path="corpus/corpus.jsonl",
        ndjson_path="corpus/arxiv.bulk.ndjson",
        index_name="arxiv",
    )
    return


def build_query(cfg: dict) -> dict:
    base_url = "http://export.arxiv.org/api/query?"

    search_query = f'all:"{cfg["query_text"]}"+AND+cat:{cfg["category"]}'
    search_query += f"+AND+submittedDate:{cfg['date_range']}"

    cfg["base_url"] = base_url
    cfg["query_params"] = {
        "search_query": search_query,
        "sortBy": cfg["sort_by"],
        "sortOrder": cfg["sort_order"],
        "start": 0,
        "max_results": cfg["page_size"],
    }
    return cfg


def fetch_arxiv_results(cfg: dict) -> list[dict]:
    all_entries = []
    max_total = cfg["max_results"]
    page_size = cfg["query_params"]["max_results"]

    for start in range(0, max_total, page_size):
        cfg["query_params"]["start"] = start
        url = cfg["base_url"] + urllib.parse.urlencode(cfg["query_params"], safe=":+[]")

        print(f"Fetching results {start} to {start + page_size}...")

        resp = requests.get(url, timeout=30)
        resp.raise_for_status()

        feed = feedparser.parse(resp.text)
        if not feed.entries:
            print("No more entries found.")
            break

        all_entries.extend(feed.entries)
        time.sleep(3)

    print(f"Fetched {len(all_entries)} total entries.")
    return all_entries


def write_jsonl_and_ndjson(entries, jsonl_path, ndjson_path, index_name):

    with open(jsonl_path, "w", encoding="utf-8") as f_jsonl, open(ndjson_path, "w", encoding="utf-8") as f_nd:
        for entry in entries:

            f_jsonl.write(json.dumps(entry, ensure_ascii=False) + "\n")

            f_nd.write(json.dumps({"index": {"_index": index_name}}) + "\n")
            f_nd.write(json.dumps(entry, ensure_ascii=False) + "\n")

    print(f"Saved {len(entries)} entries to {jsonl_path}")
    print(f"Wrote bulk file to {ndjson_path} (index={index_name})")
    return


if __name__ == "__main__":
    main()
