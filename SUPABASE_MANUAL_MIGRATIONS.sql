-- =====================================================
-- SUPABASE MANUAL MIGRATIONS
-- =====================================================
-- This file contains all database migrations in order.
-- Run these SQL statements manually in your Supabase SQL Editor.
-- 
-- IMPORTANT: Run these migrations in the exact order shown below.
-- Some migrations depend on previous ones.
-- 
-- PREREQUISITES:
-- These migrations assume your base schema is already set up with:
-- - Base tables: teams, users, customers, invoices, invoice_templates, etc.
-- - Base enums: reportTypes, invoice_status, activity_type, etc.
-- 
-- If you encounter errors about missing types or tables, ensure your
-- application's initial schema has been applied first.
-- =====================================================

-- =====================================================
-- Migration 0001: Add Report Types
-- =====================================================
-- Add new report types to the reportTypes enum
-- NOTE: reportTypes uses camelCase from the base schema

ALTER TYPE "reportTypes" ADD VALUE IF NOT EXISTS 'monthly_revenue';
ALTER TYPE "reportTypes" ADD VALUE IF NOT EXISTS 'revenue_forecast';
ALTER TYPE "reportTypes" ADD VALUE IF NOT EXISTS 'runway';
ALTER TYPE "reportTypes" ADD VALUE IF NOT EXISTS 'category_expenses';


-- =====================================================
-- Migration 0004: Add Error Code
-- =====================================================
-- This allows structured error handling with standardized codes for frontend display

ALTER TABLE accounting_sync_records 
  ADD COLUMN error_code TEXT;

-- Add comment for documentation
COMMENT ON COLUMN accounting_sync_records.error_code IS 'Standardized error code for frontend handling (e.g., ATTACHMENT_UNSUPPORTED_TYPE, AUTH_EXPIRED)';


-- =====================================================
-- Migration 0005: Add Line Item Tax
-- =====================================================
-- Adds tax_rate to invoice_products for per-product default tax rates
-- Adds include_line_item_tax toggle and label to invoice_templates

ALTER TABLE invoice_products 
  ADD COLUMN tax_rate NUMERIC(10, 2);

ALTER TABLE invoice_templates 
  ADD COLUMN include_line_item_tax BOOLEAN DEFAULT false,
  ADD COLUMN line_item_tax_label TEXT;

-- Add comments for documentation
COMMENT ON COLUMN invoice_products.tax_rate IS 'Default tax rate percentage for this product (0-100)';
COMMENT ON COLUMN invoice_templates.include_line_item_tax IS 'When true, tax is calculated per line item instead of invoice level';
COMMENT ON COLUMN invoice_templates.line_item_tax_label IS 'Custom label for the line item tax column (default: Tax)';


-- =====================================================
-- Migration 0007: Add Invoice Template ID
-- =====================================================
-- Adds template_id column to invoices table with foreign key to invoice_templates

-- Add new column
ALTER TABLE invoices 
  ADD COLUMN template_id UUID;

-- Add index for efficient lookups
CREATE INDEX IF NOT EXISTS invoices_template_id_idx ON invoices(template_id);

-- Add foreign key constraint (set null on delete to preserve invoice history)
ALTER TABLE invoices 
  ADD CONSTRAINT invoices_template_id_fkey 
  FOREIGN KEY (template_id) 
  REFERENCES invoice_templates(id) 
  ON DELETE SET NULL;


-- =====================================================
-- Migration 0008: Add Invoice Payments
-- =====================================================
-- Enables teams to accept invoice payments via Stripe

-- Add Stripe Connect fields to teams table
ALTER TABLE teams 
  ADD COLUMN IF NOT EXISTS stripe_account_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_connect_status TEXT;

-- Add payment enabled toggle to invoice templates
ALTER TABLE invoice_templates 
  ADD COLUMN IF NOT EXISTS payment_enabled BOOLEAN DEFAULT false;

-- Add payment intent tracking to invoices
ALTER TABLE invoices 
  ADD COLUMN IF NOT EXISTS payment_intent_id TEXT;

-- Add index for efficient payment intent lookups
CREATE INDEX IF NOT EXISTS invoices_payment_intent_id_idx ON invoices(payment_intent_id);

-- Add index for efficient team lookups by Stripe account ID (used by webhooks)
CREATE INDEX IF NOT EXISTS teams_stripe_account_id_idx ON teams(stripe_account_id) WHERE stripe_account_id IS NOT NULL;


-- =====================================================
-- Migration 0009: Add Refunded Status
-- =====================================================
-- Allows invoices to have a distinct "refunded" status when payment is refunded
-- NOTE: Adds value to existing invoice_status enum (must exist in base schema)

ALTER TYPE invoice_status ADD VALUE IF NOT EXISTS 'refunded';

-- Add refunded_at timestamp to track when refund occurred
ALTER TABLE invoices 
  ADD COLUMN IF NOT EXISTS refunded_at TIMESTAMP WITH TIME ZONE;


-- =====================================================
-- Migration 0010: Add Customer Enrichment
-- =====================================================
-- Adds relationship fields and AI-enriched company intelligence fields

-- ===========================================
-- CUSTOMER RELATIONSHIP FIELDS
-- ===========================================

-- Status: active, inactive, prospect, churned
ALTER TABLE customers ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- Financial defaults for invoicing
ALTER TABLE customers ADD COLUMN IF NOT EXISTS preferred_currency TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS default_payment_terms INTEGER;

-- Organization
ALTER TABLE customers ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT false;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';
ALTER TABLE customers ADD COLUMN IF NOT EXISTS external_id TEXT;

-- ===========================================
-- ENRICHMENT FIELDS (from Gemini + Grounding)
-- ===========================================

-- Visual / Brand
ALTER TABLE customers ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS brand_color TEXT;

-- Company basics
ALTER TABLE customers ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS industry TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS company_type TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS employee_count TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS founded_year INTEGER;

-- Financial intelligence
ALTER TABLE customers ADD COLUMN IF NOT EXISTS estimated_revenue TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS funding_stage TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS total_funding TEXT;

-- Location / Timezone
ALTER TABLE customers ADD COLUMN IF NOT EXISTS headquarters_location TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS timezone TEXT;

-- Social links
ALTER TABLE customers ADD COLUMN IF NOT EXISTS linkedin_url TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS twitter_url TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS instagram_url TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS facebook_url TEXT;

-- Enrichment metadata (null = not attempted, pending, processing, completed, failed)
ALTER TABLE customers ADD COLUMN IF NOT EXISTS enrichment_status TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS enriched_at TIMESTAMP WITH TIME ZONE;

-- ===========================================
-- INDEXES
-- ===========================================

CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status) WHERE status IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customers_is_archived ON customers(is_archived);
CREATE INDEX IF NOT EXISTS idx_customers_enrichment_status ON customers(enrichment_status);
CREATE INDEX IF NOT EXISTS idx_customers_website ON customers(website) WHERE website IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customers_industry ON customers(industry) WHERE industry IS NOT NULL;

-- ===========================================
-- SUPABASE REALTIME
-- Enable realtime for the customers table
-- ===========================================
ALTER PUBLICATION supabase_realtime ADD TABLE customers;


-- =====================================================
-- Migration 0010: Add Invoice Recurring
-- =====================================================
-- Enables teams to create recurring invoice series that auto-generate invoices on a schedule

-- Create frequency enum
CREATE TYPE invoice_recurring_frequency AS ENUM (
  'weekly',
  'monthly_date',
  'monthly_weekday',
  'custom'
);

-- Create end type enum
CREATE TYPE invoice_recurring_end_type AS ENUM (
  'never',
  'on_date',
  'after_count'
);

-- Create status enum
CREATE TYPE invoice_recurring_status AS ENUM (
  'active',
  'paused',
  'completed',
  'canceled'
);

-- Create invoice_recurring table
CREATE TABLE IF NOT EXISTS invoice_recurring (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  -- Frequency settings
  frequency invoice_recurring_frequency NOT NULL,
  frequency_day INTEGER, -- 0-6 for weekly (day of week), 1-31 for monthly_date
  frequency_week INTEGER, -- 1-5 for monthly_weekday (e.g., 1st, 2nd Friday)
  frequency_interval INTEGER, -- For custom: every X days
  -- End conditions
  end_type invoice_recurring_end_type NOT NULL,
  end_date TIMESTAMPTZ,
  end_count INTEGER,
  -- Status tracking
  status invoice_recurring_status DEFAULT 'active' NOT NULL,
  invoices_generated INTEGER DEFAULT 0 NOT NULL,
  consecutive_failures INTEGER DEFAULT 0 NOT NULL, -- Track failures for auto-pause
  next_scheduled_at TIMESTAMPTZ,
  last_generated_at TIMESTAMPTZ,
  timezone TEXT NOT NULL,
  -- Invoice template data
  due_date_offset INTEGER DEFAULT 30 NOT NULL,
  amount NUMERIC(10, 2),
  currency TEXT,
  line_items JSONB,
  template JSONB,
  payment_details JSONB,
  from_details JSONB,
  note_details JSONB,
  customer_name TEXT,
  vat NUMERIC(10, 2),
  tax NUMERIC(10, 2),
  discount NUMERIC(10, 2),
  subtotal NUMERIC(10, 2),
  top_block JSONB,
  bottom_block JSONB,
  template_id UUID REFERENCES invoice_templates(id) ON DELETE SET NULL
);

-- Add indexes for invoice_recurring
CREATE INDEX IF NOT EXISTS invoice_recurring_team_id_idx ON invoice_recurring(team_id);
CREATE INDEX IF NOT EXISTS invoice_recurring_next_scheduled_at_idx ON invoice_recurring(next_scheduled_at);
CREATE INDEX IF NOT EXISTS invoice_recurring_status_idx ON invoice_recurring(status);
-- Compound partial index for scheduler query (WHERE status = 'active' AND next_scheduled_at <= now)
CREATE INDEX IF NOT EXISTS invoice_recurring_active_scheduled_idx ON invoice_recurring(next_scheduled_at) WHERE status = 'active';

-- Add RLS policy for invoice_recurring
ALTER TABLE invoice_recurring ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Invoice recurring can be handled by a member of the team"
  ON invoice_recurring
  FOR ALL
  TO public
  USING (team_id IN (SELECT private.get_teams_for_authenticated_user()));

-- Add recurring invoice fields to invoices table
ALTER TABLE invoices 
  ADD COLUMN IF NOT EXISTS invoice_recurring_id UUID REFERENCES invoice_recurring(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS recurring_sequence INTEGER;

-- Add index for efficient recurring invoice lookups
CREATE INDEX IF NOT EXISTS invoices_invoice_recurring_id_idx ON invoices(invoice_recurring_id) WHERE invoice_recurring_id IS NOT NULL;

-- Unique constraint for idempotency (prevents duplicate invoices for same sequence)
CREATE UNIQUE INDEX IF NOT EXISTS invoices_recurring_sequence_unique_idx ON invoices(invoice_recurring_id, recurring_sequence) WHERE invoice_recurring_id IS NOT NULL;


-- =====================================================
-- Migration 0011: Add Customer CEO Name
-- =====================================================
-- This field stores the name of the CEO, founder, or primary executive

ALTER TABLE customers ADD COLUMN IF NOT EXISTS ceo_name TEXT;


-- =====================================================
-- Migration 0011: Add Upcoming Notification Tracking
-- =====================================================
-- Tracks when the 24-hour upcoming notification was sent to avoid duplicates

-- Add column to track when upcoming notification was sent
ALTER TABLE invoice_recurring 
  ADD COLUMN IF NOT EXISTS upcoming_notification_sent_at TIMESTAMPTZ;

-- Index for efficient querying of upcoming invoices that need notification
-- Used by the scheduler to find series due within 24 hours that haven't been notified
CREATE INDEX IF NOT EXISTS invoice_recurring_upcoming_notification_idx 
  ON invoice_recurring(next_scheduled_at, upcoming_notification_sent_at) 
  WHERE status = 'active';


-- =====================================================
-- Migration 0012: Add Customer Enrichment Fields
-- =====================================================
-- Add new customer enrichment fields

ALTER TABLE customers ADD COLUMN IF NOT EXISTS finance_contact TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS finance_contact_email TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS primary_language TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS fiscal_year_end TEXT;


-- =====================================================
-- Migration 0012: Add Recurring Frequency Options
-- =====================================================
-- These new options allow businesses to set up invoices that repeat quarterly, semi-annually, or annually

-- Add new enum values to invoice_recurring_frequency
-- Note: PostgreSQL allows adding values to enums, but not removing them
ALTER TYPE invoice_recurring_frequency ADD VALUE IF NOT EXISTS 'quarterly';
ALTER TYPE invoice_recurring_frequency ADD VALUE IF NOT EXISTS 'semi_annual';
ALTER TYPE invoice_recurring_frequency ADD VALUE IF NOT EXISTS 'annual';

-- Add recurring_invoice_upcoming to activity_type enum for 24-hour advance notifications
-- NOTE: Adds value to existing activity_type enum (must exist in base schema)
ALTER TYPE activity_type ADD VALUE IF NOT EXISTS 'recurring_invoice_upcoming';


-- =====================================================
-- Migration 0013: Add Biweekly and Last Day
-- =====================================================
-- biweekly: Every 2 weeks on the same weekday as the issue date
-- monthly_last_day: Last day of each month (handles 28/30/31 day months automatically)

-- Add new enum values to invoice_recurring_frequency
ALTER TYPE invoice_recurring_frequency ADD VALUE IF NOT EXISTS 'biweekly';
ALTER TYPE invoice_recurring_frequency ADD VALUE IF NOT EXISTS 'monthly_last_day';


-- =====================================================
-- Migration 0013: Fix Enrichment Status Default
-- =====================================================
-- Fix enrichment_status for customers without websites
-- These customers should not have a "pending" status since enrichment requires a website

-- Remove the default from enrichment_status column
ALTER TABLE customers ALTER COLUMN enrichment_status DROP DEFAULT;

-- Reset enrichment_status to null for customers without websites
-- These were incorrectly set to "pending" by the old default
UPDATE customers 
SET enrichment_status = NULL 
WHERE website IS NULL 
  AND enrichment_status = 'pending';

-- Also reset customers that have been "pending" for more than 24 hours
-- These likely had a failed job trigger and are stuck
UPDATE customers 
SET enrichment_status = NULL 
WHERE enrichment_status = 'pending' 
  AND enriched_at IS NULL
  AND created_at < NOW() - INTERVAL '24 hours';


-- =====================================================
-- Migration 0014: Add Payment Terms
-- =====================================================
-- Allows users to customize the default due date offset (in days) for invoices
-- Default is 30 days, matching the current behavior

ALTER TABLE invoice_templates 
  ADD COLUMN IF NOT EXISTS payment_terms_days INTEGER DEFAULT 30;


-- =====================================================
-- Migration 0015: Add Customer Portal
-- =====================================================
-- Adds portal_enabled and portal_id columns to customers table
-- portal_id is a short nanoid(8) used for public portal URLs

ALTER TABLE customers 
  ADD COLUMN IF NOT EXISTS portal_enabled BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS portal_id TEXT;

-- Index for efficient portal lookups by portal_id
CREATE UNIQUE INDEX IF NOT EXISTS customers_portal_id_idx 
  ON customers(portal_id) 
  WHERE portal_id IS NOT NULL;


-- =====================================================
-- Migration 0019: Fix Stuck Pending Documents
-- =====================================================
-- This migration fixes documents that are stuck in "pending" status due to previous pipeline issues

-- 1. Fix documents that have been processed (have title or content) but status was never updated
-- These are documents where classification succeeded but status wasn't set to completed
UPDATE documents 
SET 
  processing_status = 'completed',
  updated_at = NOW()
WHERE 
  processing_status = 'pending' 
  AND (title IS NOT NULL OR content IS NOT NULL);

-- 2. Mark truly stale documents as failed
-- Documents that have been pending for more than 1 hour with no content are likely stuck
-- These can be retried by users using the new reprocess functionality
UPDATE documents 
SET 
  processing_status = 'failed',
  updated_at = NOW()
WHERE 
  processing_status = 'pending' 
  AND created_at < NOW() - INTERVAL '1 hour'
  AND title IS NULL 
  AND content IS NULL;


-- =====================================================
-- END OF MIGRATIONS
-- =====================================================
-- All migrations have been applied.
-- Your Supabase database should now be up to date.
-- =====================================================
