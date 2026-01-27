-- Migration: Add is_admin and email columns to user_mapping table
-- Created: 2026-01-18
-- Description: Adds admin status tracking and email for easy user identification

-- Add email column so users can be identified in Supabase Dashboard
ALTER TABLE user_mapping 
ADD COLUMN IF NOT EXISTS email TEXT;

-- Add is_admin column with default value of false
ALTER TABLE user_mapping 
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false NOT NULL;

-- Create index for faster admin checks
CREATE INDEX IF NOT EXISTS idx_user_mapping_clerk_user_id ON user_mapping(clerk_user_id);

-- Create index for email lookups
CREATE INDEX IF NOT EXISTS idx_user_mapping_email ON user_mapping(email);

-- Set admin status for the user with email sohammisal22@gmail.com
-- This will work after the app populates the email column
UPDATE user_mapping 
SET is_admin = true 
WHERE email = 'sohammisal22@gmail.com';

-- Add comments to the columns for documentation
COMMENT ON COLUMN user_mapping.is_admin IS 'Indicates if user has admin privileges. Manage via Supabase Dashboard.';
COMMENT ON COLUMN user_mapping.email IS 'User email from Clerk for easy identification in dashboard.';
