-- Add AI-generated venture intelligence scores to startup_analyses.
ALTER TABLE public.startup_analyses
  ADD COLUMN IF NOT EXISTS market_potential_score INT,
  ADD COLUMN IF NOT EXISTS technical_complexity_score INT;
