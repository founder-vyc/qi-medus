# Supabase Manual Migrations Guide

This directory contains all SQL migrations for the qi-medus (Midday) application that need to be run manually in Supabase.

## Files

- **`SUPABASE_MANUAL_MIGRATIONS.sql`** - Single consolidated file containing ALL migrations in order
- **`packages/db/migrations/`** - Individual migration files (original source)

## How to Run Migrations in Supabase

### Option 1: Run All Migrations at Once (Recommended for New Setup)

1. Log in to your [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy the entire contents of `SUPABASE_MANUAL_MIGRATIONS.sql`
6. Paste into the SQL editor
7. Click **Run** or press `Ctrl+Enter` / `Cmd+Enter`

### Option 2: Run Individual Migrations (For Selective Updates)

If you only need to run specific migrations or prefer a step-by-step approach:

1. Navigate to the `packages/db/migrations/` directory
2. Open the migration files in numerical order (e.g., `0001_...`, `0004_...`, etc.)
3. Copy each migration's SQL content
4. Run in Supabase SQL Editor one at a time

## Migration List

The following migrations are included (in order):

1. **0001_add_report_types.sql** - Add new report types enum values
2. **0004_add_error_code.sql** - Add error_code column for accounting sync
3. **0005_add_line_item_tax.sql** - Add line item tax support for invoices
4. **0007_add_invoice_template_id.sql** - Add template_id to invoices
5. **0008_add_invoice_payments.sql** - Add Stripe Connect payment support
6. **0009_add_refunded_status.sql** - Add refunded status for invoices
7. **0010_add_customer_enrichment.sql** - Add AI-enriched customer fields
8. **0010_add_invoice_recurring.sql** - Add recurring invoice functionality
9. **0011_add_customer_ceo_name.sql** - Add CEO name field to customers
10. **0011_add_upcoming_notification_tracking.sql** - Track recurring invoice notifications
11. **0012_add_customer_enrichment_fields.sql** - Add additional enrichment fields
12. **0012_add_recurring_frequency_options.sql** - Add quarterly, semi-annual, annual frequencies
13. **0013_add_biweekly_and_last_day.sql** - Add biweekly and monthly_last_day frequencies
14. **0013_fix_enrichment_status_default.sql** - Fix enrichment status for customers without websites
15. **0014_add_payment_terms.sql** - Add payment_terms_days to invoice templates
16. **0015_add_customer_portal.sql** - Add customer portal support
17. **0019_fix_stuck_pending_documents.sql** - Fix documents stuck in pending status

## Prerequisites

Before running these migrations, ensure you have:

- A Supabase project created
- Access to the Supabase SQL Editor
- The following tables already exist in your database:
  - `teams`
  - `users`
  - `customers`
  - `invoices`
  - `invoice_templates`
  - `invoice_products`
  - `accounting_sync_records`
  - `documents`

These base tables should be created by your application's initial schema setup.

## Important Notes

### IF NOT EXISTS Clauses

Most migrations use `IF NOT EXISTS` or `ADD COLUMN IF NOT EXISTS` clauses, which means:

- ✅ Safe to run multiple times
- ✅ Won't fail if the column/table/index already exists
- ✅ Idempotent operations

### Enum Values

PostgreSQL enum operations (`ALTER TYPE ... ADD VALUE`) are:

- ✅ Idempotent with `IF NOT EXISTS`
- ⚠️ Cannot be removed once added
- ⚠️ Must be run outside of transactions in some cases

If you encounter errors with enum values, you may need to run them separately or skip them if they already exist.

### Update Statements

Two migrations contain UPDATE statements that modify existing data:

- **0013_fix_enrichment_status_default.sql** - Resets enrichment_status for certain customers
- **0019_fix_stuck_pending_documents.sql** - Fixes stuck pending documents

These are safe to run and will only affect rows matching specific conditions.

## Troubleshooting

### Error: "relation does not exist"

This means a required table hasn't been created yet. Ensure your application's base schema is set up before running migrations.

### Error: "type already exists"

This is safe to ignore if using `IF NOT EXISTS`. The type already exists in your database.

### Error: "column already exists"

This is safe to ignore if using `ADD COLUMN IF NOT EXISTS`. The column already exists in your database.

### Error: "constraint already exists"

Some constraints may fail if they already exist. You can either:
- Skip that specific statement (it's already applied)
- Drop the constraint first and re-add it

## Verification

After running migrations, verify they were applied successfully:

```sql
-- Check if new columns exist on customers table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'customers' 
  AND column_name IN ('ceo_name', 'portal_enabled', 'finance_contact');

-- Check if invoice_recurring table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'invoice_recurring'
);

-- Check enum values
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = 'invoice_recurring_frequency'::regtype;
```

## Next Steps

After running migrations:

1. Update your environment variables (see `SETUP.md`)
2. Run the application with `bun dev`
3. Test invoice and customer functionality
4. Verify recurring invoice features work correctly

## Support

For questions or issues:
- Check the main [README.md](./README.md)
- Review [SETUP.md](./SETUP.md) for complete setup instructions
- Open an issue on GitHub

## License

Same as main project - AGPL-3.0 for non-commercial use.
