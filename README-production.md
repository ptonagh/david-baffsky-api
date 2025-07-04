# David Baffsky AO - Production API

A production-ready API server for the David Baffsky AO digital legacy application, featuring Claude AI integration and conversation persistence.

## Features

- 🤖 **Claude AI Integration** - Secure API proxy with conversation context
- 💾 **Database Persistence** - PostgreSQL for conversation history
- 🔒 **Security** - Environment variables, CORS protection, input validation
- 📊 **Analytics** - Usage tracking and conversation metrics
- 🚀 **Production Ready** - Error handling, logging, health checks
- ⚡ **Scalable** - Optimized for Railway deployment

## Quick Deploy to Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template)

## Environment Variables

Required:
- `CLAUDE_API_KEY` - Your Claude API key from Anthropic
- `DATABASE_URL` - PostgreSQL connection string (Railway provides automatically)

Optional:
- `PORT` - Server port (default: 3333)
- `NODE_ENV` - Environment (production/development)
- `ALLOWED_ORIGINS` - CORS allowed origins (comma-separated)

## Local Development

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Copy environment template:**
   ```bash
   cp .env.example .env
   ```

3. **Add your Claude API key to `.env`:**
   ```
   CLAUDE_API_KEY=your_actual_api_key_here
   ```

4. **Start development server:**
   ```bash
   npm run dev
   ```

5. **Test the API:**
   ```bash
   curl http://localhost:3333/health
   ```

## API Endpoints

### Health Check
```
GET /health
```
Returns server status and database connection info.

### Claude Chat
```
POST /api/claude
```
Proxy requests to Claude AI with conversation persistence.

Headers:
- `x-session-id`: Unique session identifier
- `x-topic`: Conversation topic

Body:
```json
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": "Hello David"
    }
  ]
}
```

### Conversation History
```
GET /api/conversations/:sessionId/:topic
```
Retrieve conversation history for a session and topic.

### Analytics
```
GET /api/analytics
```
Get usage statistics (last 30 days).

## Database Schema

### Conversations Table
```sql
CREATE TABLE conversations (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    topic VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Messages Table
```sql
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER REFERENCES conversations(id),
    role VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Production Deployment

### Railway (Recommended)

1. **Fork this repository**
2. **Connect to Railway:**
   - Go to railway.app
   - Click "Deploy from GitHub"
   - Select your forked repository
3. **Add environment variables:**
   - `CLAUDE_API_KEY`: Your Claude API key
4. **Add PostgreSQL database:**
   - Railway will automatically set `DATABASE_URL`
5. **Deploy!**

### Manual Deployment

1. **Build Docker image:**
   ```bash
   docker build -t david-baffsky-api .
   ```

2. **Run container:**
   ```bash
   docker run -p 3333:3333 -e CLAUDE_API_KEY=your_key david-baffsky-api
   ```

## Security Features

- ✅ Environment variable validation
- ✅ CORS protection with configurable origins
- ✅ Request size limiting (10MB)
- ✅ Input validation and sanitization
- ✅ Error message filtering in production
- ✅ Graceful shutdown handling
- ✅ SQL injection protection (parameterized queries)

## Monitoring

The API includes built-in monitoring:

- **Health endpoint** for uptime checks
- **Request logging** with timestamps
- **Error tracking** with stack traces (dev only)
- **Database connection monitoring**
- **Usage analytics** for optimization

## License

MIT License - see LICENSE file for details.

## Support

For deployment issues:
- Check the [Railway documentation](https://docs.railway.app)
- Review the health endpoint: `/health`
- Check server logs in Railway dashboard