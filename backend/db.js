const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false
    }
});

pool.on('connect', () => {
    console.log('Connected to the database');
});

const fs = require('fs');
const path = require('path');

const initDb = async () => {
    try {
        const schemaPath = path.join(__dirname, 'schema.sql');
        if (fs.existsSync(schemaPath)) {
            const schema = fs.readFileSync(schemaPath, 'utf8');
            await pool.query(schema);
            // Patch existing table if needed
            await pool.query('ALTER TABLE users ALTER COLUMN phone DROP NOT NULL').catch(() => { });
            console.log('Database initialized successfully');
        }
    } catch (err) {
        console.error('Database initialization error:', err);
    }
};

module.exports = {
    query: (text, params) => pool.query(text, params),
    initDb
};
