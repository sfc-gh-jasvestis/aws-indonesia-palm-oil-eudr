-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for EUDR Compliance Engine
-- ============================================================================
USE DATABASE PALM_OIL_EUDR;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.EUDR_COMPLIANCE_AGENT
  COMMENT = 'EUDR Compliance Engine AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'PALM_OIL_EUDR.APP.EUDR_COMPLIANCE_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'PALM_OIL_EUDR.SEARCH.COMPLIANCE_DOCS_SEARCH', TOOL_DESCRIPTION => 'Search documents for Palm Oil & Agriculture information')
  )
  SYSTEM_PROMPT = 'You are the EUDR Compliance Agent for Indonesia''s palm oil industry, helping verify deforestation-free supply chains for EU market access across 15,000 georeferenced plots.';
