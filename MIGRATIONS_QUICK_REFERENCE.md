# Quick Reference: SQL Migrations

This is a quick reference guide showing all 17 migrations that can be run manually in Supabase.

## Files Location

- **All-in-one file**: `SUPABASE_MANUAL_MIGRATIONS.sql` (427 lines)
- **Individual files**: `packages/db/migrations/*.sql`
- **Usage guide**: `SUPABASE_MIGRATIONS_README.md`

## Complete Migration List

| # | File | Description |
|---|------|-------------|
| 1 | `0001_add_report_types.sql` | Add new report types to reportTypes enum (monthly_revenue, revenue_forecast, runway, category_expenses) |
| 2 | `0004_add_error_code.sql` | Add error_code column to accounting_sync_records for structured error handling |
| 3 | `0005_add_line_item_tax.sql` | Add line item tax support (tax_rate for products, include_line_item_tax toggle) |
| 4 | `0007_add_invoice_template_id.sql` | Add template_id to invoices table with foreign key to invoice_templates |
| 5 | `0008_add_invoice_payments.sql` | Add Stripe Connect payment support (stripe_account_id, payment_intent_id) |
| 6 | `0009_add_refunded_status.sql` | Add 'refunded' status to invoice_status enum and refunded_at timestamp |
| 7 | `0010_add_customer_enrichment.sql` | Add AI-enriched customer fields (logo, industry, funding, social links, etc.) |
| 8 | `0010_add_invoice_recurring.sql` | Add complete recurring invoice functionality with schedules and automation |
| 9 | `0011_add_customer_ceo_name.sql` | Add ceo_name field to customers table |
| 10 | `0011_add_upcoming_notification_tracking.sql` | Add upcoming_notification_sent_at to track 24-hour advance notifications |
| 11 | `0012_add_customer_enrichment_fields.sql` | Add finance contact, language, and fiscal year fields |
| 12 | `0012_add_recurring_frequency_options.sql` | Add quarterly, semi_annual, and annual frequency options |
| 13 | `0013_add_biweekly_and_last_day.sql` | Add biweekly and monthly_last_day frequency options |
| 14 | `0013_fix_enrichment_status_default.sql` | Fix enrichment_status for customers without websites (includes UPDATE) |
| 15 | `0014_add_payment_terms.sql` | Add payment_terms_days to invoice_templates (default: 30) |
| 16 | `0015_add_customer_portal.sql` | Add customer portal support (portal_enabled, portal_id) |
| 17 | `0019_fix_stuck_pending_documents.sql` | Fix documents stuck in pending status (includes UPDATE) |

## Key Features by Migration

### Invoice Features
- **Line item tax**: #3 (0005)
- **Template tracking**: #4 (0007)
- **Payment processing**: #5 (0008)
- **Refund handling**: #6 (0009)
- **Recurring invoices**: #8 (0010), #10 (0011), #12 (0012), #13 (0013)
- **Payment terms**: #15 (0014)

### Customer Features
- **AI enrichment**: #7 (0010), #11 (0012)
- **CEO/executive info**: #9 (0011)
- **Customer portal**: #16 (0015)

### System Features
- **Report types**: #1 (0001)
- **Error handling**: #2 (0004)
- **Document processing**: #17 (0019)

## Tables Modified

| Table | Migrations |
|-------|-----------|
| `accounting_sync_records` | 0004 |
| `customers` | 0010, 0011, 0012, 0013, 0015 |
| `documents` | 0019 |
| `invoice_products` | 0005 |
| `invoice_recurring` | 0010, 0011, 0012, 0013 |
| `invoice_templates` | 0005, 0008, 0014 |
| `invoices` | 0007, 0008, 0009, 0010 |
| `teams` | 0008 |

## New Tables Created

- `invoice_recurring` (Migration 0010)

## New Enums Created

- `invoice_recurring_frequency` (Migration 0010, extended in 0012, 0013)
- `invoice_recurring_end_type` (Migration 0010)
- `invoice_recurring_status` (Migration 0010)

## Migrations with Data Updates

⚠️ These migrations modify existing data:

- **0013_fix_enrichment_status_default.sql** - Resets enrichment_status to NULL for:
  - Customers without websites
  - Customers pending for >24 hours
  
- **0019_fix_stuck_pending_documents.sql** - Updates document statuses:
  - Sets to 'completed' if title/content exists
  - Sets to 'failed' if pending >1 hour with no content

## How to Use

### Option 1: Run Everything (New Setup)
```bash
# Copy and paste the entire SUPABASE_MANUAL_MIGRATIONS.sql file
# into Supabase SQL Editor and run it
```

### Option 2: Run Individual Migrations
```bash
# Navigate to packages/db/migrations/
# Run each migration file in order (0001, 0004, 0005, etc.)
```

### Option 3: Run Specific Migrations
```bash
# If you only need invoice features, run:
# 0005, 0007, 0008, 0009, 0010, 0011, 0012, 0013, 0014

# If you only need customer features, run:
# 0010, 0011, 0012, 0013, 0015
```

## Safety Notes

✅ **Safe to re-run**: Most migrations use `IF NOT EXISTS` clauses
✅ **Idempotent**: Can be run multiple times without errors
⚠️ **Enum values**: Cannot be removed once added
⚠️ **Data updates**: Two migrations update existing data (0013, 0019)

## Need Help?

See `SUPABASE_MIGRATIONS_README.md` for detailed instructions and troubleshooting.
