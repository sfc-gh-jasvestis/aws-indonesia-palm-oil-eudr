'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';
import { GeoMap } from '@/components/GeoMap';
import { ArchitectureDiagram } from '@/components/ArchitectureDiagram';

interface DemoNarrative {
  title: string;
  duration: string;
  thesis: string;
  tabs: any[];
}

export default function HomePage() {
  const [narrative, setNarrative] = useState<DemoNarrative | null>(null);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch('/demo_narrative.json')
      .then((r) => r.json())
      .then(setNarrative)
      .catch(() => {});
    fetch('/api/data')
      .then((r) => r.json())
      .then(setData)
      .catch(() => {});
  }, []);


  // Look up a KPI value returned by /api/data (sourced from CURATED.KPI_SUMMARY).
  // Falls back to the original literal so the card still renders if the API,
  // or KPI_SUMMARY, is unavailable.
  const kpiVal = (title: string, fallback: string): string =>
    (data?.kpiCards as { title: string; value: string }[] | undefined)
      ?.find((k) => k.title === title)?.value ?? fallback;

  const title = narrative?.title || 'SEA AWS Demo';

  const executiveCockpit = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard title="EUDR Compliant Lots" value={kpiVal('EUDR Compliant Lots', '87%')} status="warning" />
        <KPICard title="Deforestation-Free" value={kpiVal('Deforestation-Free', '94%')} status="neutral" />
        <KPICard title="Smallholders Mapped" value={kpiVal('Smallholders Mapped', '42K')} status="neutral" />
        <KPICard title="Due Diligence Statements" value={kpiVal('Due Diligence Statements', '1,247')} status="neutral" />
      </div>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="lg:col-span-1">
          <GeoMap
            country="indonesia"
            labels={{ entity: 'Suppliers', event: 'Satellite Alerts', alert: 'Deforestation Alerts' }}
            regions={data?.regions}
            markers={[{"label": "Medan", "value": "N.Sumatra: 847 estates", "color": "green", "size": "lg"}, {"label": "Palembang", "value": "S.Sumatra: EUDR alert", "color": "amber", "size": "md"}, {"label": "Pontianak", "value": "W.Kalimantan: 412 mills", "color": "green", "size": "md"}, {"label": "Balikpapan", "value": "E.Kalimantan: replanting", "color": "blue", "size": "md"}, {"label": "Jakarta", "value": "Trading desk", "color": "blue", "size": "sm"}]}
            routes={[{"from": "Medan", "to": "Jakarta", "color": "#10B981"}]}
            title="Geographic Overview"
            height={400}
          />
        </div>
        <div className="lg:col-span-1 grid grid-cols-1 gap-4">
      <div className="grid grid-cols-1 gap-4 grid-cols-1">
        <Chart
          data={data?.timeseries || [{ period: 'Jan', value: 112 }, { period: 'Feb', value: 118 }, { period: 'Mar', value: 135 }, { period: 'Apr', value: 148 }, { period: 'May', value: 156 }, { period: 'Jun', value: 142 }, { period: 'Jul', value: 138 }, { period: 'Aug', value: 151 }, { period: 'Sep', value: 144 }, { period: 'Oct', value: 132 }, { period: 'Nov', value: 121 }, { period: 'Dec', value: 115 }]}
          type="line"
          xKey="period"
          yKeys={[{ key: 'value', name: '% Compliant' }]}
          title="EUDR Compliance Progress (Monthly)"
        />
        <Chart
          data={data?.categories || [{ category: 'North', count: 82 }, { category: 'Central', count: 74 }, { category: 'South', count: 91 }, { category: 'Highland', count: 68 }, { category: 'Coastal', count: 77 }]}
          type="bar"
          xKey="category"
          yKeys={[{ key: 'count', name: 'Risk Score' }]}
          title="Risk Assessment by Supplier"
        />
      </div>
        </div>
      </div>
      <DataTable
        columns={[
          { key: 'id', header: '#' },
          { key: 'name', header: 'Supplier' },
          { key: 'region', header: 'Region' },
          { key: 'status', header: 'EUDR Status' },
          { key: 'm1', header: 'Compliance %' },
          { key: 'm2', header: 'Deforestation Free' },
          { key: 'm3', header: 'Forest Proximity Risk' },
          { key: 'events', header: 'Satellite Alerts' },
          { key: 'alerts', header: 'Deforestation Alerts' },
        ]}
        data={data?.entities || []}
        title="Supplier EUDR Status"
      />
    </div>
  );

  const domainTab1 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KPICard title="Plots Geolocated" value={kpiVal('Plots Geolocated', '98.4%')} />
        <KPICard title="Satellite Alerts (30d)" value={kpiVal('Satellite Alerts (30d)', '12')} />
        <KPICard title="Forest Proximity Risk" value={kpiVal('Forest Proximity Risk', '4.2%')} />
      </div>
      <Chart
        data={data?.detail || [{ x: 'Mon', y: 24 }, { x: 'Tue', y: 28 }, { x: 'Wed', y: 22 }, { x: 'Thu', y: 31 }, { x: 'Fri', y: 26 }, { x: 'Sat', y: 19 }, { x: 'Sun', y: 23 }]}
        type="area"
        xKey="x"
        yKeys={[{ key: 'y', name: 'Alerts' }]}
        title="Deforestation Alerts by District"
        height={400}
      />
    </div>
  );

  const domainTab2 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart
          data={data?.regionAlerts || [{ label: 'Zone North', value: 35 }, { label: 'Zone Central', value: 28 }, { label: 'Zone South', value: 22 }, { label: 'Zone East', value: 15 }]}
          type="pie"
          xKey="label"
          yKeys={[{ key: 'value', name: 'Statements' }]}
          title="Statement Submission Timeline"
        />
        <ActionMemo
          persona={{ name: 'Sri Mulyani Hartono', role: 'EUDR Compliance Director' }}
          context={{}}
          onGenerate={async () => {
            const memos = [
              {
                subject: 'Urgent: Operational Action Required',
                body: `Dear Leadership Team,\n\nBased on our analysis of the latest operational data, I am writing to recommend immediate action on the following critical items.\n\nKey Findings:\n- Performance metrics indicate a deviation from target KPIs in several areas\n- Predictive models suggest these trends will continue without intervention\n- Estimated impact: 12-15% improvement in efficiency if addressed within 2 weeks\n\nI recommend we schedule a review meeting this week to align on next steps.\n\nBest regards`,
                urgency: 'HIGH' as const,
                actions: ['Complete geolocation for remaining 2.4K smallholder plots', 'Submit Due Diligence Statement for EU Batch#EU-2024-847', 'Investigate satellite alert in Kalimantan Barat block'],
              },
              {
                subject: 'Weekly Performance Summary & Recommendations',
                body: `Dear Team,\n\nPlease find below the AI-generated weekly performance summary.\n\nHighlights:\n- Overall performance trending 8% above quarterly targets\n- Three areas identified for optimization with potential 20% cost savings\n- New anomaly patterns detected that warrant monitoring\n\nRecommended next steps are outlined below. Please review and confirm priority assignments by end of week.\n\nRegards`,
                urgency: 'MEDIUM' as const,
                actions: ['Complete geolocation for remaining 2.4K smallholder plots', 'Submit Due Diligence Statement for EU Batch#EU-2024-847', 'Investigate satellite alert in Kalimantan Barat block'],
              },
              {
                subject: 'Strategic Initiative: Data-Driven Optimization',
                body: `Dear Stakeholders,\n\nOur AI analysis has identified a significant opportunity for operational optimization.\n\nExecutive Summary:\n- Current utilization rate: 78% (target: 90%)\n- Root cause analysis points to 3 primary factors\n- Projected ROI of recommended changes: 2.4x within 6 months\n\nThe attached data supports a phased implementation approach starting with the highest-impact items.\n\nPlease advise on scheduling a planning session.\n\nBest regards`,
                urgency: 'HIGH' as const,
                actions: ['Complete geolocation for remaining 2.4K smallholder plots', 'Submit Due Diligence Statement for EU Batch#EU-2024-847', 'Investigate satellite alert in Kalimantan Barat block'],
              },
            ];
            return memos[Math.floor(Math.random() * memos.length)];
          }}
        />
      </div>
    </div>
  );

  const askAiTab = (
    <div className="h-[600px]">
      <AskAI
        title="Ask AI"
        sampleQuestions={[
          'Which suppliers are not yet EUDR compliant?',
          'Show deforestation alert trends by province',
          'What is the risk score for our EU-bound supply chain?',
        ]}
        mode="sql"
        onSubmit={async (question, mode) => {
          return {
            answer: `[Demo Mode] Response to: "${question}" (${mode} mode). Connect to Snowflake for live data.`,
            sql: mode === 'sql' ? 'SELECT * FROM CURATED.SUMMARY LIMIT 10;' : undefined,
          };
        }}
      />
    </div>
  );

  const architectureTab = (
    <ArchitectureDiagram
      snowflakeFeatures={['Dynamic Tables (5-min refresh)', 'ML Functions (Forecast + Anomaly)', 'Cortex Search + Agent', 'Semantic View + Intelligence', 'Alerts + Notifications']}
      awsServices={[{ name: 'Amazon S3', role: 'Strategy Docs' }, { name: 'Amazon S3 + Kinesis', role: 'Integration' }, { name: 'Amazon SNS', role: 'Integration' }, { name: 'Amazon QuickSight + Q', role: 'Integration' }]}
    />
  );

  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '📊', content: executiveCockpit },
    { id: 'domain-1', label: 'Geospatial', icon: '📈', content: domainTab1 },
    { id: 'domain-2', label: 'Due Diligence', icon: '⚡', content: domainTab2 },
    { id: 'ask-ai', label: 'Ask AI', icon: '🤖', content: askAiTab },
    { id: 'architecture', label: 'Architecture & Data', icon: '🏗️', content: architectureTab },
  ];

  return (
    <AppLayout
      title={title}
      tabs={tabs}
      narrative={narrative}
    />
  );
}
