-- Validate the producer contract before building downstream objects.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

EXECUTE IMMEDIATE $$
DECLARE
  violations INTEGER;
  invalid_source EXCEPTION (-20001, 'Synthetic source failed grain or measure validation');
BEGIN
  SELECT COUNT(*) INTO :violations FROM (
    SELECT ENTITY_ID, EVENT_DATE
    FROM RAW.SUPPLY_DAILY
    GROUP BY ENTITY_ID, EVENT_DATE HAVING COUNT(*) <> 1
    UNION ALL
    SELECT observation.ENTITY_ID, observation.EVENT_DATE
    FROM RAW.SUPPLY_DAILY observation
    LEFT JOIN RAW.SUPPLY_BASES supply_base ON supply_base.ID = observation.ENTITY_ID
    WHERE supply_base.ID IS NULL OR observation.DELIVERY_COUNT < 0
       OR observation.TRACED_TONNES < 0 OR observation.FFB_TONNES <= 0
       OR observation.CONFIRMED_COUNT < 0 OR observation.CONFIRMED_COUNT > observation.FLAG_COUNT
       OR observation.LOTS_EXCLUDED > observation.CONFIRMED_COUNT
       OR observation.DECLARATION_RECEIVED > observation.DECLARATION_DUE
  );
  IF (violations > 0) THEN
    RAISE invalid_source;
  END IF;
END;
$$;
