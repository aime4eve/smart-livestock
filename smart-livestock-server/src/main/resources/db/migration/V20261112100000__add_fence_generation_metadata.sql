-- Fence generation metadata: opaque JSON describing how the fence was
-- generated (e.g. DEVICE_TRACK draft params). Written only at creation;
-- NULL for fences created through any other path.
ALTER TABLE fences ADD COLUMN generation_metadata jsonb NULL;
