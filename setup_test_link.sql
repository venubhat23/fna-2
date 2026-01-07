-- Link a customer to test 5 test 5 affiliate (ID 46)
-- First, find a customer with Ram in their name
-- Update: let's just pick the first customer and link them

UPDATE customers
SET sub_agent_id = 46
WHERE id = 1;

-- Check the result
SELECT c.id, c.first_name, c.last_name, c.sub_agent_id, s.first_name as affiliate_first_name, s.last_name as affiliate_last_name
FROM customers c
LEFT JOIN sub_agents s ON c.sub_agent_id = s.id
WHERE c.id = 1;