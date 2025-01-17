-- Function to update timestamp
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW."updated_at" := now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION gen_random_uuid_v7()
    RETURNS uuid
    AS $$
    SELECT
        encode(set_bit(set_bit(overlay(uuid_send(gen_random_uuid())
                    PLACING substring(int8send(floor(extract(epoch FROM clock_timestamp()) * 1000)::bigint)
                    FROM 3)
                FROM 1 FOR 6), 52, 1), 53, 1), 'hex')::uuid;
$$
LANGUAGE SQL
VOLATILE;

