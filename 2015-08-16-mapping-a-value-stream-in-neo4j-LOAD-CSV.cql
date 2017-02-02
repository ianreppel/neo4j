/**
 * Databaseline code repository
 *
 * Code for post: Mapping a Value Stream in Neo4j
 * Compatibility: Neo4j 2.1.8
 * Base URL:      https://databaseline.bitbucket.io
 * Author:        Ian Hellström
 *
 * Notes:         LOAD CSV is available from 2.1.8
 *                CREATE CONSTRAINT/INDEX are available from 2.0.5
 *                OPTIONAL MATCH is available from 2.0.5
 */

// Add indexes and constraints for improved performance with LOAD CSV and MATCH/MERGE
CREATE INDEX ON :Supplier(name)
CREATE INDEX ON :Customer(name)
CREATE INDEX ON :Product(name)
CREATE INDEX ON :Product(facility)

CREATE CONSTRAINT ON (s:Supplier) ASSERT s.id IS UNIQUE
CREATE CONSTRAINT ON (c:Customer) ASSERT c.id IS UNIQUE
CREATE CONSTRAINT ON (p:Product)  ASSERT p.id IS UNIQUE

// Load CSV files (UTF-8 without BOM) from local path one at a time
LOAD CSV WITH HEADERS FROM 'file:///path/to/suppliers.csv' AS row
CREATE (s:Supplier { id: toInt(row.SUPPLIER_ID),
                     name: row.SUPPLIER_DESC,
                     location: row.COUNTRY })

LOAD CSV WITH HEADERS FROM 'file:///path/to/customers.csv' AS row
CREATE (c:Customer { id: toInt(row.CUSTOMER_ID),
                     name: row.CUSTOMER_DESC,
                     location: row.CITY })

LOAD CSV WITH HEADERS FROM 'file:///path/to/products.csv' AS row
CREATE (p:Product { id: toInt(row.PRODUCT_ID),
                    name: row.PRODUCT_DESC,
                    facility: row.FACILITY_DESC,
                    duration: toFloat(row.CYCLE_TIME_DAYS) })

LOAD CSV WITH HEADERS FROM 'file:///path/to/product_yield.csv' AS row
MATCH (p:Product { name: row.PRODUCT_DESC, 
                   facility: row.FACILITY_DESC })
SET p.yield = toFloat(row.LINE_YIELD)

LOAD CSV WITH HEADERS FROM 'file:///path/to/bom.csv' AS row
MATCH  (s:Supplier { id: toInt(row.SUPPLIER_ID) }),
       (p:Product { id: toInt(row.PRODUCT_ID) })
CREATE (s)-[:PROVIDES { material: row.SUPPLIER_PRODUCT_DESC }]->(p)

LOAD CSV WITH HEADERS FROM 'file:///path/to/demand.csv' AS row
MATCH  (c:Customer { id: toInt(row.CUSTOMER_ID) }),
       (p:Product { id: toInt(row.PRODUCT_ID) })
CREATE (c)-[:REQUIRES]->(p)

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM 'file:///path/to/product_mapping.csv' AS row
MATCH (src:Product { id: toInt(row.FROM_PRODUCT) }),
      (tgt:Product { id: toInt(row.TO_PRODUCT) })
CREATE (src)-[:MOVES_TO { transport: toFloat(row.TRANSPORT_TIME_DAYS) }]->(tgt)

// Remove constraints (as they are only relevant for LOAD CSV with MATCH/MERGE)
DROP CONSTRAINT ON (s:Supplier) ASSERT s.id IS UNIQUE
DROP CONSTRAINT ON (c:Customer) ASSERT c.id IS UNIQUE
DROP CONSTRAINT ON (p:Product)  ASSERT p.id IS UNIQUE

// Remove IDs (as they are no longer required)
MATCH (n)
WHERE n:Supplier OR n:Customer OR n:Product
REMOVE n.id
