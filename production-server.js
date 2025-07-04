const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3333;

// Environment variables validation
const requiredEnvVars = ['CLAUDE_API_KEY'];
const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingEnvVars.length > 0) {
    console.error('❌ Missing required environment variables:', missingEnvVars.join(', '));
    console.error('Please set these in your environment or .env file');
    process.exit(1);
}

// Database connection
let db = null;
if (process.env.DATABASE_URL) {
    db = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
    });
    
    // Test database connection
    db.connect()
        .then(() => console.log('✅ Database connected successfully'))
        .catch(err => console.error('❌ Database connection failed:', err.message));
} else {
    console.log('⚠️  No DATABASE_URL found - running without persistent storage');
}

// Middleware
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Health check endpoint
app.get('/', (req, res) => {
    res.json({ 
        message: 'David Baffsky API is running!', 
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development'
    });
});

app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        database: db ? 'connected' : 'not configured',
        timestamp: new Date().toISOString()
    });
});

// Initialize database tables
async function initializeDatabase() {
    if (!db) return;
    
    try {
        // Create conversations table
        await db.query(`
            CREATE TABLE IF NOT EXISTS conversations (
                id SERIAL PRIMARY KEY,
                session_id VARCHAR(255) NOT NULL,
                topic VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Create messages table
        await db.query(`
            CREATE TABLE IF NOT EXISTS messages (
                id SERIAL PRIMARY KEY,
                conversation_id INTEGER REFERENCES conversations(id),
                role VARCHAR(50) NOT NULL,
                content TEXT NOT NULL,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Create index for faster queries
        await db.query(`
            CREATE INDEX IF NOT EXISTS idx_conversations_session 
            ON conversations(session_id)
        `);
        
        await db.query(`
            CREATE INDEX IF NOT EXISTS idx_messages_conversation 
            ON messages(conversation_id)
        `);

        console.log('✅ Database tables initialized');
    } catch (error) {
        console.error('❌ Database initialization failed:', error.message);
    }
}

// Save conversation to database
async function saveConversation(sessionId, topic) {
    if (!db) return null;
    
    try {
        const result = await db.query(
            'INSERT INTO conversations (session_id, topic) VALUES ($1, $2) RETURNING id',
            [sessionId, topic]
        );
        return result.rows[0].id;
    } catch (error) {
        console.error('Error saving conversation:', error.message);
        return null;
    }
}

// Save message to database
async function saveMessage(conversationId, role, content) {
    if (!db || !conversationId) return;
    
    try {
        await db.query(
            'INSERT INTO messages (conversation_id, role, content) VALUES ($1, $2, $3)',
            [conversationId, role, content]
        );
    } catch (error) {
        console.error('Error saving message:', error.message);
    }
}

// Get conversation history from database
async function getConversationHistory(sessionId, topic) {
    if (!db) return [];
    
    try {
        const result = await db.query(`
            SELECT m.role, m.content, m.timestamp
            FROM conversations c
            JOIN messages m ON c.id = m.conversation_id
            WHERE c.session_id = $1 AND c.topic = $2
            ORDER BY m.timestamp ASC
        `, [sessionId, topic]);
        
        return result.rows;
    } catch (error) {
        console.error('Error getting conversation history:', error.message);
        return [];
    }
}

// Claude API proxy endpoint
app.post('/api/claude', async (req, res) => {
    try {
        console.log('📨 Received request to /api/claude');
        
        // Extract session info for conversation persistence
        const sessionId = req.headers['x-session-id'] || 'anonymous';
        const topic = req.headers['x-topic'] || 'general';
        
        // Validate request body
        if (!req.body || !req.body.messages || !Array.isArray(req.body.messages)) {
            return res.status(400).json({ 
                error: 'Invalid request format',
                details: 'Request must include messages array'
            });
        }

        console.log('🔄 Processing Claude API request...');
        
        // Forward request to Claude API
        const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': process.env.CLAUDE_API_KEY,
                'anthropic-version': '2023-06-01'
            },
            body: JSON.stringify({
                model: req.body.model || 'claude-3-5-sonnet-20241022',
                max_tokens: req.body.max_tokens || 1024,
                messages: req.body.messages
            })
        });
        
        console.log(`📡 Claude API response status: ${claudeResponse.status}`);
        
        if (!claudeResponse.ok) {
            const errorText = await claudeResponse.text();
            console.error('❌ Claude API error:', errorText);
            return res.status(claudeResponse.status).json({ 
                error: 'Claude API error', 
                details: errorText,
                status: claudeResponse.status
            });
        }
        
        const data = await claudeResponse.json();
        console.log('✅ Claude API response received successfully');
        
        // Save conversation to database if enabled
        if (db && data.content && data.content[0]) {
            try {
                // Get or create conversation
                let conversationId = await saveConversation(sessionId, topic);
                
                if (conversationId) {
                    // Save user message
                    const userMessage = req.body.messages[req.body.messages.length - 1];
                    await saveMessage(conversationId, userMessage.role, userMessage.content);
                    
                    // Save Claude's response
                    await saveMessage(conversationId, 'assistant', data.content[0].text);
                }
            } catch (dbError) {
                console.error('Database save error:', dbError.message);
                // Continue with response even if DB save fails
            }
        }
        
        res.json(data);
        
    } catch (error) {
        console.error('❌ Proxy server error:', error);
        res.status(500).json({ 
            error: 'Internal server error', 
            details: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
        });
    }
});

// Get conversation history endpoint
app.get('/api/conversations/:sessionId/:topic', async (req, res) => {
    try {
        const { sessionId, topic } = req.params;
        const history = await getConversationHistory(sessionId, topic);
        res.json({ history });
    } catch (error) {
        console.error('Error fetching conversation history:', error);
        res.status(500).json({ error: 'Failed to fetch conversation history' });
    }
});

// Analytics endpoint (for monitoring usage)
app.get('/api/analytics', async (req, res) => {
    if (!db) {
        return res.json({ error: 'Database not configured' });
    }
    
    try {
        const stats = await db.query(`
            SELECT 
                COUNT(DISTINCT session_id) as unique_users,
                COUNT(*) as total_conversations,
                COUNT(m.*) as total_messages
            FROM conversations c
            LEFT JOIN messages m ON c.id = m.conversation_id
            WHERE c.created_at >= NOW() - INTERVAL '30 days'
        `);
        
        const topicStats = await db.query(`
            SELECT topic, COUNT(*) as count
            FROM conversations
            WHERE created_at >= NOW() - INTERVAL '30 days'
            GROUP BY topic
            ORDER BY count DESC
        `);
        
        res.json({
            last_30_days: stats.rows[0],
            popular_topics: topicStats.rows
        });
    } catch (error) {
        console.error('Analytics error:', error);
        res.status(500).json({ error: 'Failed to fetch analytics' });
    }
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    res.status(500).json({ 
        error: 'Internal server error',
        details: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('🔄 SIGTERM received, shutting down gracefully...');
    if (db) {
        await db.end();
    }
    process.exit(0);
});

// Initialize database and start server
async function startServer() {
    await initializeDatabase();
    
    app.listen(PORT, '0.0.0.0', () => {
        console.log('\n🚀 David Baffsky API Server Started!');
        console.log('=====================================');
        console.log(`📍 Server running on port ${PORT}`);
        console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
        console.log(`🔑 Claude API: ${process.env.CLAUDE_API_KEY ? 'Configured' : 'Missing!'}`);
        console.log(`💾 Database: ${db ? 'Connected' : 'Not configured'}`);
        console.log(`🌐 CORS Origins: ${process.env.ALLOWED_ORIGINS || 'All origins allowed'}`);
        console.log('=====================================');
        console.log(`✅ Health check: http://localhost:${PORT}/health`);
        console.log(`🤖 Claude endpoint: http://localhost:${PORT}/api/claude`);
        console.log('=====================================\n');
    });
}

startServer().catch(error => {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
});

module.exports = app;