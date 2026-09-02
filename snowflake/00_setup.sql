-- Generated from generator/demo_specs/aws-indonesia-palm-oil-eudr.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-indonesia-palm-oil-eudr
-- This is the schema that is actually deployed for ID_PALM_OIL_EUDR.

-- ID_PALM_OIL_EUDR  (EUDR Compliance Engine)
-- generated from generator/demo_specs/aws-indonesia-palm-oil-eudr.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS ID_PALM_OIL_EUDR;
CREATE SCHEMA IF NOT EXISTS ID_PALM_OIL_EUDR.RAW;
CREATE SCHEMA IF NOT EXISTS ID_PALM_OIL_EUDR.CURATED;
CREATE SCHEMA IF NOT EXISTS ID_PALM_OIL_EUDR.APP;
USE DATABASE ID_PALM_OIL_EUDR;

-- 5 real regions; entity names carry their region so the two always agree
