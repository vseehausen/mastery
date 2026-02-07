-- Change default session time from 10 minutes to 5 minutes
ALTER TABLE user_learning_preferences ALTER COLUMN daily_time_target_minutes SET DEFAULT 5;
