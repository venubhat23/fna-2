-- Update specific SubAgent password to match mobile app change
UPDATE sub_agents
SET plain_password = 'password122',
    updated_at = NOW()
WHERE email = 'dsn101171@gmail.com';

-- Show the result
SELECT id, email, first_name, last_name, plain_password
FROM sub_agents
WHERE email = 'dsn101171@gmail.com';