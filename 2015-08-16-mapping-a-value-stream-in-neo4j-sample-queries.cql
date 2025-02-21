/**
 * Databaseline code repository
 *
 * Code for post: Mapping a Value Stream in Neo4j
 * Compatibility: Neo4j 2.0.5
 * Base URL:      https://ianreppel.org
 * Author:        Ian Reppel
 *
 * Notes:         OPTIONAL MATCH is available from 2.0.5
 */

// Remove all nodes and relationships among the nodes
MATCH (n)
OPTIONAL MATCH (n)-[r]-()
DELETE n,r

// Return all nodes and relationships
MATCH (n)
RETURN n

// Calculate the total line yield for the "Plain Ol' Choc" production chain
MATCH
  p=(s)-[:MOVES_TO*]->(t)
WHERE
  s:Product
  AND t:Product
  AND s.name = 'Plain Ol' Choc'
  AND NOT ()-[:MOVES_TO]->(s)
  AND NOT (t)-[:MOVES_TO]->()
RETURN
  s                                              AS source_product
, t                                              AS final_product
, reduce(steps = 0, n IN nodes(p) | steps + 1)   AS num_steps
, reduce(yld = 1, n IN nodes(p) | yld * n.yield) AS chain_yield

// Show the Product subgraph related to "Cheapo Choc"
MATCH
  p=(s)-[:MOVES_TO*]-(t)
WHERE
  s:Product
  AND s.name = 'Cheapo Choc'
RETURN
  nodes(p) AS path

// Calculate the total cycle time (production + transportation) for all products
MATCH
  p=(s:Product)-[:MOVES_TO*]->(t:Product)
WHERE
  NOT ()-[:MOVES_TO]->(s)
  AND NOT (t)-[:MOVES_TO]->()
RETURN
  t.name                                                        AS product 
, MAX(reduce(pt = 0, n IN nodes(p) | pt + n.duration))          AS production_time
, MAX(reduce(tt = 0, r IN relationships(p) | tt + r.transport)) AS transport_time

// Find all Suppliers involved in the production of "Hot as Hell", including all its customers
MATCH
  path=(s:Supplier)-[*]->(p:Product { name: 'Hot as Hell'} )<-[:REQUIRES]-(c:Customer)
RETURN 
  path

// The same as before but with a list instead of a graph
MATCH
  path=(s:Supplier)-[*]->(p:Product { name: 'Hot as Hell'} )<-[:REQUIRES]-(c:Customer)
RETURN 
  p                        AS product
, collect(DISTINCT s.name) AS supplier_list
, collect(DISTINCT c.name) AS customer_list
