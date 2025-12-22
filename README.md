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

## Exploring the Data

1. Open http://localhost:5601
2. Go to Stack Management -> Data Views
3. Create a data view:
    - Index pattern: `arxiv`
    - Time field: published (optional)
Use **Discover** to browse and search documents.

## Future Work
- Visualizations and dashboards
- Stable Document IDs
- Chunking and normalization
- Vector embeddings
- RAG pipelines