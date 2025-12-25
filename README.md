# arxiv-rag

This project fetches metadata from the arXiv API, stores it as JSONL and Elasticsearch Bulk NDJSON, and indexes it into an Elasticsearch + Kibana stack running in Docker.

At present, this repository focuses on **arXiv metadata collection and Elasticsearch indexing**.

## Prerequisites

You will need:

- **Conda** (Miniconda or Anaconda)
- **Docker** (with Docker Compose v2)
- `curl`

## Installation

### 1. Clone the repository
```
git clone git@github.com:4l3xv33/arxiv-rag.git
cd arxiv-rag
```

### 2. Create and activate the Conda environment

```
conda env create
conda activate arxiv-rag-elk-env
```

### 3. Start Elasticsearch + Kibana (Docker)

```
docker compose up -d
```

Verify services:

- Elasticsearch: http://localhost:9200
- Kibana: http://localhost:5601

### 4. Fetch arXiv data and generate artifacts

Run the data collection script.

```
python fetch_arxiv.py
```

This will generate:

- `corpus/corpus.jsonl` (canonical JSONL dataset)
- `corpus/arxiv.bulk.ndjson` (Elasticsearch Bulk API format)

## Elasticsearch Indexing

### 5. Create the `arxiv` index

```
curl -X PUT "http://localhost:9200/arxiv" \
  -H "Content-Type: application/json" \
  -d '{
    "mappings": {
      "dynamic": true
    }
  }'

```

This creates a flexible index that accepts documents as-is.

### 6. Bulk ingest into Elasticsearch

```
curl --fail-with-body -sS \
  -H "Content-Type: application/x-ndjson" \
  -X POST "http://localhost:9200/_bulk?refresh=true" \
  --data-binary "@corpus/arxiv.bulk.ndjson"

```

**Warning**: Re-running the bulk ingest without deleting the index or using stable document IDs will create duplicate documents. To delete and recreate the index during experimentation, use `curl -X DELETE "http://localhost:9200/arxiv"` and `curl -X PUT "http://localhost:9200/arxiv"`.

Verify ingestion:

```
curl "http://localhost:9200/arxiv/_count?pretty"

```

## Data Structure

```json
{
  "id": "http://arxiv.org/abs/2512.16795v1",
  "guidislink": true,
  "link": "https://arxiv.org/abs/2512.16795v1",
  "title": "From Facts to Conclusions : Integrating Deductive Reasoning in Retrieval-Augmented LLMs",
  "title_detail": {
    "type": "text/plain",
    "language": null,
    "base": "",
    "value": "From Facts to Conclusions : Integrating Deductive Reasoning in Retrieval-Augmented LLMs"
  },
  "updated": "2025-12-18T17:27:51Z",
  "updated_parsed": [
    2025,
    12,
    18,
    17,
    27,
    51,
    3,
    352,
    0
  ],
  "links": [
    {
      "href": "https://arxiv.org/abs/2512.16795v1",
      "rel": "alternate",
      "type": "text/html"
    },
    {
      "href": "https://arxiv.org/pdf/2512.16795v1",
      "rel": "related",
      "type": "application/pdf",
      "title": "pdf"
    }
  ],
  "summary": "Retrieval-Augmented Generation (RAG) grounds large language models (LLMs) in external evidence, but fails when retrieved sources conflict or contain outdated or subjective information. Prior work address these issues independently but lack unified reasoning supervision. We propose a reasoning-trace-augmented RAG framework that adds structured, interpretable reasoning across three stages : (1) document-level adjudication, (2) conflict analysis, and (3) grounded synthesis, producing citation-linked answers or justified refusals. A Conflict-Aware Trust-Score (CATS) pipeline is introduced which evaluates groundedness, factual correctness, refusal accuracy, and conflict-behavior alignment using an LLM-as-a-Judge. Our 539-query reasoning dataset and evaluation pipeline establish a foundation for conflict-aware, interpretable RAG systems. Experimental results demonstrate substantial gains over baselines, most notably with Qwen, where Supervised Fine-Tuning improved End-to-End answer correctness from 0.069 to 0.883 and behavioral adherence from 0.074 to 0.722.",
  "summary_detail": {
    "type": "text/plain",
    "language": null,
    "base": "",
    "value": "Retrieval-Augmented Generation (RAG) grounds large language models (LLMs) in external evidence, but fails when retrieved sources conflict or contain outdated or subjective information. Prior work address these issues independently but lack unified reasoning supervision. We propose a reasoning-trace-augmented RAG framework that adds structured, interpretable reasoning across three stages : (1) document-level adjudication, (2) conflict analysis, and (3) grounded synthesis, producing citation-linked answers or justified refusals. A Conflict-Aware Trust-Score (CATS) pipeline is introduced which evaluates groundedness, factual correctness, refusal accuracy, and conflict-behavior alignment using an LLM-as-a-Judge. Our 539-query reasoning dataset and evaluation pipeline establish a foundation for conflict-aware, interpretable RAG systems. Experimental results demonstrate substantial gains over baselines, most notably with Qwen, where Supervised Fine-Tuning improved End-to-End answer correctness from 0.069 to 0.883 and behavioral adherence from 0.074 to 0.722."
  },
  "tags": [
    {
      "term": "cs.CL",
      "scheme": "http://arxiv.org/schemas/atom",
      "label": null
    },
    {
      "term": "cs.AI",
      "scheme": "http://arxiv.org/schemas/atom",
      "label": null
    },
    {
      "term": "cs.CY",
      "scheme": "http://arxiv.org/schemas/atom",
      "label": null
    },
    {
      "term": "cs.IR",
      "scheme": "http://arxiv.org/schemas/atom",
      "label": null
    }
  ],
  "published": "2025-12-18T17:27:51Z",
  "published_parsed": [
    2025,
    12,
    18,
    17,
    27,
    51,
    3,
    352,
    0
  ],
  "arxiv_comment": "Under Review",
  "arxiv_primary_category": {
    "term": "cs.CL"
  },
  "authors": [
    {
      "name": "Shubham Mishra"
    },
    {
      "name": "Samyek Jain"
    },
    {
      "name": "Gorang Mehrishi"
    },
    {
      "name": "Shiv Tiwari"
    },
    {
      "name": "Harsh Sharma"
    },
    {
      "name": "Pratik Narang"
    },
    {
      "name": "Dhruv Kumar"
    }
  ],
  "author_detail": {
    "name": "Dhruv Kumar"
  },
  "author": "Dhruv Kumar"
}

```


## Exploring the Data

1. Open http://localhost:5601
2. Go to Stack Management -> Data Views
3. Create a data view:
    - Index pattern: `arxiv`
    - Time field: published (optional)
Use **Discover** to browse and search documents.

## Future Work
- Visualizations and dashboards
- Adding a Makefile for crade to grave process
- Stable Document IDs
- Chunking and normalization
- Vector embeddings
- RAG pipelines