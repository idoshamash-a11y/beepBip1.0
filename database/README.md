# Database Setup Guide

This guide explains how to set up the BEEPBIP database in Supabase.

## Overview

The database schema includes:
- User management with unique serial IDs
- Personal and Business profiles
- Location tracking
- Privacy and visibility settings
- Row Level Security (RLS) policies

## Setup Steps

### 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign in or create an account
3. Click "New Project"
4. Fill in project details:
   - Name: BEEPBIP
   - Database Password: (choose a strong password)
   - Region: (select closest to your users)
5. Click "Create new project"
6. Wait for database provisioning (2-3 minutes)

### 2. Run Schema Script

1. In your Supabase dashboard, navigate to "SQL Editor"
2. Click "New query"
3. Open the `schema.sql` file from this directory
4. Copy the entire contents
5. Paste into the SQL Editor
6. Click "Run" to execute
7. Verify success - you should see "Success. No rows returned"

### 3. Verify Tables Created

Go to "Table Editor" and verify these tables exist:
- `users`
- `profiles`
- `personal_profiles`
- `business_profiles`
- `business_hours`
- `locations`
- `interests`

### 4. Test Serial ID Generation

Run this test query in SQL Editor:
```sql
-- This will be automatically triggered when a user signs up
-- Testing the function manually:
SELECT generate_serial_id();
```

You should see a serial ID like: `BP-A3F9D2`

### 5. Enable Real-time (Optional)

For real-time features:
1. Go to "Database" > "Replication"
2. Enable replication for these tables:
   - `profiles`
   - `locations`
3. Click "Save"

## Database Features

### Automatic Serial ID Generation

When a user signs up via Supabase Auth:
1. A trigger automatically creates a record in `users` table
2. A unique serial ID is generated (format: `BP-XXXXXX`)
3. The serial ID is guaranteed to be unique

### Row Level Security (RLS)

RLS policies ensure:
- Users can only view their own private data
- Users can view "open" profiles from others
- Users cannot modify other users' data
- Location sharing respects privacy settings

### Profile Types

**Personal Profiles:**
- Can be Free or Premium tier
- Include: name, photo, bio, interests
- Privacy controls for visibility

**Business Profiles:**
- Require Premium tier
- Include: business name, logo, description, services
- Support multiple locations
- Business hours management

### Location Sharing Options

1. **Don't Share**: Profile not visible on map
2. **Visible Without Location**: Profile shows on map without exact coordinates
3. **Visible With Location**: Profile and exact location visible

## Testing the Database

### Create Test User Profile

```sql
-- 1. First, sign up a user through the app or Supabase Auth

-- 2. Verify user was created
SELECT * FROM users LIMIT 1;

-- 3. Create a test personal profile (replace USER_ID with actual user ID)
INSERT INTO profiles (user_id, profile_type)
VALUES ('USER_ID', 'personal')
RETURNING *;

-- 4. Add personal profile details (replace PROFILE_ID)
INSERT INTO personal_profiles (id, name, interests)
VALUES ('PROFILE_ID', 'Test User', ARRAY['Sports', 'Music'])
RETURNING *;

-- 5. Add a location
INSERT INTO locations (profile_id, latitude, longitude, is_primary)
VALUES ('PROFILE_ID', 40.7128, -74.0060, true)
RETURNING *;
```

### Test RLS Policies

```sql
-- Test as authenticated user
-- (RLS policies use auth.uid() to identify the current user)

-- View own profile (should work)
SELECT * FROM profiles WHERE user_id = auth.uid();

-- View own personal profile (should work)
SELECT pp.*
FROM personal_profiles pp
JOIN profiles p ON p.id = pp.id
WHERE p.user_id = auth.uid();

-- View open profiles from others (should work)
SELECT * FROM profiles WHERE visibility_status = 'open';
```

## Stored Procedures for Location Queries

For nearby profile searches, you'll need to create this RPC function:

```sql
CREATE OR REPLACE FUNCTION get_nearby_profiles(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 10.0
)
RETURNS TABLE (
  profile_id UUID,
  profile_type TEXT,
  distance_km DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.profile_id,
    p.profile_type::TEXT,
    earth_distance(
      ll_to_earth(lat, lng),
      ll_to_earth(l.latitude, l.longitude)
    ) / 1000.0 AS distance_km
  FROM locations l
  JOIN profiles p ON p.id = l.profile_id
  WHERE
    p.visibility_status = 'open'
    AND p.location_sharing IN ('visible_without_location', 'visible_with_location')
    AND earth_box(ll_to_earth(lat, lng), radius_km * 1000) @> ll_to_earth(l.latitude, l.longitude)
  ORDER BY distance_km
  LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Database Indexes

The schema includes indexes for optimal performance:
- Serial ID lookups
- User ID foreign keys
- Visibility status filtering
- Spatial queries on locations
- Interest and service arrays (GIN indexes)

## Backup and Migration

### Export Schema
```bash
# Using Supabase CLI
supabase db dump -f schema.sql

# Or from SQL Editor
# Copy all table definitions and run locally
```

### Migration Strategy

For schema changes:
1. Create migration file
2. Test in development project
3. Apply to production
4. Update `schema.sql` in repository

## Troubleshooting

### Issue: Serial ID not generating

**Solution:**
```sql
-- Check if trigger exists
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';

-- Recreate trigger if missing
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_user_profile();
```

### Issue: RLS blocking queries

**Solution:**
```sql
-- Check which policies are active
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Temporarily disable RLS for testing (DEVELOPMENT ONLY!)
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Re-enable when done
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
```

### Issue: Can't query locations

**Solution:**
```sql
-- Ensure earth extension is enabled
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;
```

## Security Best Practices

1. **Never disable RLS in production**
2. **Always use parameterized queries** from the app
3. **Rotate database password** regularly
4. **Use service role key** only in backend, never in mobile app
5. **Monitor database logs** for suspicious activity
6. **Set up database backups** in Supabase dashboard

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostGIS for Location Queries](https://postgis.net/)
