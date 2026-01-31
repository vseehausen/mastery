-- Enable realtime for sync-relevant tables
ALTER PUBLICATION supabase_realtime ADD TABLE vocabulary;
ALTER PUBLICATION supabase_realtime ADD TABLE learning_cards;
ALTER PUBLICATION supabase_realtime ADD TABLE sources;
ALTER PUBLICATION supabase_realtime ADD TABLE encounters;
