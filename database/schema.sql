-- BEEPBIP Database Schema for Supabase
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- USERS TABLE (extends Supabase auth.users)
-- =============================================
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  serial_id TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_seen_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE
);

-- Generate unique serial ID function
CREATE OR REPLACE FUNCTION generate_serial_id()
RETURNS TEXT AS $$
DECLARE
  new_serial_id TEXT;
  done BOOLEAN := FALSE;
BEGIN
  WHILE NOT done LOOP
    -- Generate format: BP-XXXXXX (6 random alphanumeric characters)
    new_serial_id := 'BP-' || upper(substring(md5(random()::text) from 1 for 6));

    -- Check if it already exists
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE serial_id = new_serial_id) THEN
      done := TRUE;
    END IF;
  END LOOP;

  RETURN new_serial_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate serial_id
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, serial_id, email)
  VALUES (
    NEW.id,
    generate_serial_id(),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_user_profile();

-- =============================================
-- PROFILE TYPES ENUM
-- =============================================
CREATE TYPE profile_type AS ENUM ('personal', 'business');
CREATE TYPE subscription_tier AS ENUM ('free', 'premium');
CREATE TYPE visibility_status AS ENUM ('open', 'closed');
CREATE TYPE location_sharing AS ENUM ('dont_share', 'visible_without_location', 'visible_with_location');

-- =============================================
-- PROFILES TABLE (Base for both Personal & Business)
-- =============================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  profile_type profile_type NOT NULL,
  subscription_tier subscription_tier DEFAULT 'free',
  visibility_status visibility_status DEFAULT 'open',
  location_sharing location_sharing DEFAULT 'dont_share',
  is_profile_complete BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, profile_type)
);

-- =============================================
-- PERSONAL PROFILES TABLE
-- =============================================
CREATE TABLE public.personal_profiles (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  photo_url TEXT,
  bio TEXT,
  interests TEXT[], -- Array of interest tags
  date_of_birth DATE,
  gender TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- BUSINESS PROFILES TABLE
-- =============================================
CREATE TABLE public.business_profiles (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  logo_url TEXT,
  description TEXT,
  category TEXT,
  services TEXT[], -- Array of services offered
  website TEXT,
  phone TEXT,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- BUSINESS HOURS TABLE
-- =============================================
CREATE TABLE public.business_hours (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_profile_id UUID REFERENCES public.business_profiles(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Sunday, 6=Saturday
  open_time TIME,
  close_time TIME,
  is_closed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- LOCATIONS TABLE (for both Personal and Business profiles)
-- =============================================
CREATE TABLE public.locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  postal_code TEXT,
  is_primary BOOLEAN DEFAULT FALSE,
  location_name TEXT, -- For businesses with multiple locations
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create spatial index for location queries
CREATE INDEX idx_locations_coordinates ON public.locations USING gist (
  ll_to_earth(latitude, longitude)
);

-- =============================================
-- INTERESTS/TAGS TABLE
-- =============================================
CREATE TABLE public.interests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  category TEXT,
  icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view their own user data"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own user data"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- Profiles table policies
CREATE POLICY "Users can view their own profiles"
  ON public.profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view open profiles"
  ON public.profiles FOR SELECT
  USING (visibility_status = 'open');

CREATE POLICY "Users can insert their own profiles"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profiles"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own profiles"
  ON public.profiles FOR DELETE
  USING (auth.uid() = user_id);

-- Personal profiles policies
CREATE POLICY "Users can view their own personal profiles"
  ON public.personal_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = personal_profiles.id
      AND profiles.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view open personal profiles"
  ON public.personal_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = personal_profiles.id
      AND profiles.visibility_status = 'open'
    )
  );

CREATE POLICY "Users can insert their own personal profiles"
  ON public.personal_profiles FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = personal_profiles.id
      AND profiles.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own personal profiles"
  ON public.personal_profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = personal_profiles.id
      AND profiles.user_id = auth.uid()
    )
  );

-- Business profiles policies (similar structure)
CREATE POLICY "Users can view their own business profiles"
  ON public.business_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = business_profiles.id
      AND profiles.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view open business profiles"
  ON public.business_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = business_profiles.id
      AND profiles.visibility_status = 'open'
    )
  );

CREATE POLICY "Users can insert their own business profiles"
  ON public.business_profiles FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = business_profiles.id
      AND profiles.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own business profiles"
  ON public.business_profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = business_profiles.id
      AND profiles.user_id = auth.uid()
    )
  );

-- Business hours policies
CREATE POLICY "Anyone can view business hours"
  ON public.business_hours FOR SELECT
  USING (true);

CREATE POLICY "Users can manage their business hours"
  ON public.business_hours FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.business_profiles bp
      JOIN public.profiles p ON p.id = bp.id
      WHERE bp.id = business_hours.business_profile_id
      AND p.user_id = auth.uid()
    )
  );

-- Locations policies
CREATE POLICY "Users can view their own locations"
  ON public.locations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = locations.profile_id
      AND profiles.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view open profile locations based on sharing settings"
  ON public.locations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = locations.profile_id
      AND profiles.visibility_status = 'open'
      AND profiles.location_sharing IN ('visible_without_location', 'visible_with_location')
    )
  );

CREATE POLICY "Users can manage their own locations"
  ON public.locations FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = locations.profile_id
      AND profiles.user_id = auth.uid()
    )
  );

-- =============================================
-- FUNCTIONS FOR UPDATED_AT TIMESTAMP
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_personal_profiles_updated_at BEFORE UPDATE ON public.personal_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_business_profiles_updated_at BEFORE UPDATE ON public.business_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_locations_updated_at BEFORE UPDATE ON public.locations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX idx_users_serial_id ON public.users(serial_id);
CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX idx_profiles_visibility ON public.profiles(visibility_status);
CREATE INDEX idx_profiles_type ON public.profiles(profile_type);
CREATE INDEX idx_personal_profiles_interests ON public.personal_profiles USING GIN(interests);
CREATE INDEX idx_business_profiles_services ON public.business_profiles USING GIN(services);
CREATE INDEX idx_locations_profile_id ON public.locations(profile_id);
CREATE INDEX idx_business_hours_business_profile_id ON public.business_hours(business_profile_id);
