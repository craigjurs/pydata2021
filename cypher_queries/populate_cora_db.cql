// Create constraints
CREATE CONSTRAINT papers IF NOT EXISTS ON (p:Paper) ASSERT p.id IS UNIQUE;

// Load node list
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/craigjurs/pydata2021/main/notebooks/data/cora_nodes.csv' AS line
WITH line
MERGE (p:Paper {id: line.id})
    ON CREATE SET p.subject = line.subject, p.features = line.features
RETURN COUNT(*)

// Load edge list
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/craigjurs/pydata2021/main/notebooks/data/cora_edges.csv' AS line
WITH line
MATCH (source:Paper {id: line.source})
MATCH (target:Paper {id: line.target})
MERGE (source)-[:CITES]->(target)
RETURN COUNT(*)

// Create in-memory graph of (Paper)-[:CITES]-(Paper)
CALL gds.graph.create(
    'cora',
    'Paper',
    {CITES: 
        {
            orientation: 'UNDIRECTED'
        }
    }
)

// Stream FastRP embeddings
CALL gds.fastRP.stream('cora',
 {
     embeddingDimension: 10
    }
)
YIELD nodeId, embedding
RETURN gds.util.asNode(nodeId).id AS id, embedding
LIMIT 10

// If things get really broken, delete the graph and start over
MATCH (n) DETACH DELETE n

