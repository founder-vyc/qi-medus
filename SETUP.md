# Setup and Testing Guide

This guide provides step-by-step instructions for setting up and running the Midday platform after removing all business features except invoices and assistant.

## Prerequisites

- **Bun** v1.2.22 or later ([Installation guide](https://bun.sh/docs/installation))
- **Node.js** v18 or later (for compatibility)
- **Docker** (for running local Redis)
- **Supabase** account (for database and auth)

## Repository Structure (After Changes)

The platform now contains:

### Packages (13)
- `invoice` - Core invoice functionality
- `cache`, `db`, `email`, `encryption`, `engine-client`, `events`, `logger`, `notifications`, `supabase`, `tsconfig`, `ui`, `utils` - Core infrastructure

### Apps (3)
- `api` - API server (tRPC)
- `dashboard` - Main dashboard application (Next.js)
- `engine` - Engine service

### Dashboard Routes (4)
- `[[...chatId]]` - AI Assistant/Chat interface
- `invoices` - Invoice management
- `account` - Account settings
- `settings` - General settings

## Setup Instructions

### 1. Install Dependencies

```bash
# Install Bun if not already installed
curl -fsSL https://bun.sh/install | bash

# Install project dependencies
bun install
```

### 2. Environment Configuration

#### Dashboard (.env)
Create `apps/dashboard/.env` from `.env-example`:

```bash
cp apps/dashboard/.env-example apps/dashboard/.env
```

**Required variables for basic functionality:**
```env
# Supabase (Database & Auth)
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_KEY=your_service_key

# API URLs
NEXT_PUBLIC_API_URL=http://localhost:3003
NEXT_PUBLIC_URL=http://localhost:3001

# OpenAI (for Assistant)
OPENAI_API_KEY=your_openai_key

# Invoice
INVOICE_JWT_SECRET=secret

# File encryption
FILE_KEY_SECRET=secret

# Engine
ENGINE_API_KEY=secret
ENGINE_API_URL=http://localhost:3002
```

#### API (.env)
Create `apps/api/.env` from `.env-template`:

```bash
cp apps/api/.env-template apps/api/.env
```

**Required variables:**
```env
# Database
DATABASE_PRIMARY_URL=your_supabase_database_url
SUPABASE_SERVICE_KEY=your_service_key
SUPABASE_URL=your_supabase_url

# OpenAI (for Assistant)
OPENAI_API_KEY=your_openai_key

# Config
ALLOWED_API_ORIGINS=http://localhost:3001
INVOICE_JWT_SECRET=secret
MIDDAY_ENCRYPTION_KEY=your_encryption_key

# Redis (for caching)
REDIS_URL=redis://localhost:6379
```

#### Engine (.env)
Create `apps/engine/.env` if needed for additional configuration.

### 3. Start Redis (for API caching)

```bash
# Start Redis with Docker
docker run -d --name redis -p 6379:6379 redis:alpine

# Verify Redis is running
docker ps | grep redis
```

### 4. Database Setup

If using Supabase:
1. Create a new project at [supabase.com](https://supabase.com)
2. Copy the database URL and API keys to your .env files
3. Run migrations if available

## Running the Application

### Option 1: Run All Services (Development)

```bash
# Start all services in parallel
bun dev
```

This will start:
- Dashboard on `http://localhost:3001`
- Engine on `http://localhost:3002`
- API on `http://localhost:3003`

### Option 2: Run Services Individually

```bash
# Terminal 1 - Dashboard
bun dev:dashboard

# Terminal 2 - API
bun dev:api

# Terminal 3 - Engine
bun dev:engine
```

## Testing the Application

### 1. Verify Services are Running

**Dashboard:**
```bash
curl http://localhost:3001
```
Expected: HTML response or redirect to login

**API:**
```bash
curl http://localhost:3003/health
```
Expected: Health check response

**Engine:**
```bash
curl http://localhost:3002/health
```
Expected: Health check response

### 2. Test Invoice Functionality

1. Open browser to `http://localhost:3001`
2. Sign in with your Supabase credentials
3. Navigate to `/invoices` route
4. Verify you can:
   - View invoice list
   - Create new invoice
   - Edit existing invoice
   - Generate invoice PDF

### 3. Test Assistant Functionality

1. While logged in, navigate to the chat interface
2. The route should be accessible (e.g., `http://localhost:3001/[locale]/chat`)
3. Verify you can:
   - Send messages to the assistant
   - Receive AI responses
   - View chat history

### 4. Run Automated Tests

```bash
# Run all tests
bun test

# Run tests for specific app
cd apps/api && bun test
cd apps/dashboard && bun test
cd apps/engine && bun test
```

### 5. Type Checking

```bash
# Check TypeScript types across all packages
bun typecheck
```

### 6. Linting

```bash
# Run linter
bun lint

# Format code
bun format
```

## Building for Production

### Build All Apps

```bash
bun run build
```

### Build Individual Apps

```bash
# Dashboard
bun run build:dashboard

# API (if applicable)
cd apps/api && bun run build

# Engine (if applicable)
cd apps/engine && bun run build
```

### Start Production Build

```bash
# Dashboard
bun run start:dashboard
```

## Troubleshooting

### Common Issues

#### 1. Redis Connection Error
**Error:** `Error: connect ECONNREFUSED 127.0.0.1:6379`

**Solution:**
```bash
# Ensure Redis is running
docker start redis

# Or restart Redis
docker restart redis
```

#### 2. Supabase Connection Error
**Error:** `Error: Invalid Supabase URL`

**Solution:**
- Verify your Supabase URL in .env files
- Check that your Supabase project is active
- Ensure API keys are correct

#### 3. OpenAI API Error
**Error:** `Error: Invalid API key`

**Solution:**
- Verify your OpenAI API key is set in both API and Dashboard .env files
- Check that the key has sufficient credits

#### 4. Port Already in Use
**Error:** `Error: Port 3001 is already in use`

**Solution:**
```bash
# Find and kill the process using the port
lsof -ti:3001 | xargs kill -9

# Or use a different port by modifying the package.json scripts
```

### Verify What Was Removed

The following features have been removed and should NOT be accessible:

**Removed Packages:**
- accounting, app-store, categories, customers, desktop-client, documents, import, inbox, job-client, jobs, location, plans, workbench

**Removed Apps:**
- desktop, docs, website, worker

**Removed Dashboard Routes:**
- `/customers`, `/inbox`, `/tracker`, `/transactions`, `/vault`, `/apps`, `/upgrade`

If you try to access these routes, you should get a 404 error.

## Quick Verification Checklist

- [ ] All dependencies installed (`bun install`)
- [ ] Environment variables configured
- [ ] Redis running (for API)
- [ ] Supabase project configured
- [ ] Dashboard starts on port 3001
- [ ] API starts on port 3003
- [ ] Engine starts on port 3002
- [ ] Can access login page
- [ ] Can access `/invoices` route after login
- [ ] Can access chat/assistant interface
- [ ] Removed routes return 404
- [ ] Tests pass (`bun test`)
- [ ] Type checking passes (`bun typecheck`)
- [ ] Linting passes (`bun lint`)

## Support

For issues or questions:
1. Check this guide first
2. Review the main [README.md](./README.md)
3. Check individual app READMEs in `apps/*/README.md`
4. Open an issue on GitHub

## What's Working

After the changes, the platform provides:

✅ **Invoice System** - Full invoice creation, editing, and management
✅ **AI Assistant** - Chat-based AI assistant for business queries
✅ **Core Infrastructure** - Database, caching, email, notifications, UI components
✅ **Authentication** - User login and account management
✅ **Settings** - User and application settings

All other business features have been successfully removed without breaking these core functionalities.
