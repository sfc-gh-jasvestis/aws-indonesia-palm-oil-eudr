'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';

interface SupplyData {
  platform: 'snowflake' | 'aws';
  kpiCards: { title: string; value: string }[];
  timeseries: { period: string; deliveries: number | null; flags: number | null }[];
  categories: { category: string; flags: number | null; confirmed: number | null }[];
  entities: Record<string, string | number | null>[];
  declarationRisk: { name: string; compliance: number; confirmed: number }[];
  sourceWatermark: string | null;
  rawWatermark: string | null;
  requestedAt: string;
  stale: boolean;
  pipelineBehind: boolean;
  risk: Record<string, string | number | null>[];
  holdout: { n: number | null; baseRate: number | null; precision: number | null; recall: number | null } | null;
  forecast: { period: string; value: number | null; lower: number | null; upper: number | null }[];
  live: Record<string, string | number | null>[];
  liveSummary: { n: number | null; flags: number | null; lastLoaded: string | null; medianLagSeconds: number | null };
  anomalies: Record<string, string | number | null>[];
  alerts: Record<string, string | number | null>[];
}

const pct = (value: number | null) => (value === null ? 'n/a' : `${(value * 100).toFixed(0)}%`);

export default function HomePage() {
  const [data, setData] = useState<SupplyData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    setError(null);
    setData(null);
    fetch('/api/data', { cache: 'no-store', signal: controller.signal })
      .then(async (response) => {
        if (!response.ok) throw new Error('Data request failed');
        const payload = await response.json();
        if (!Array.isArray(payload.kpiCards) || !Array.isArray(payload.entities)) throw new Error('Invalid contract');
        return payload;
      })
      .then(setData)
      .catch(() => {
        if (!controller.signal.aborted) setError('Snowflake data is unavailable. No fallback values are displayed.');
      })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [attempt]);

  const isAws = (data?.platform ?? 'aws') === 'aws';
  const awsDiagram = { key: 'aws', title: 'AWS + Snowflake', src: '/architecture-aws.html' };
  const sfDiagram = { key: 'snowflake', title: 'Snowflake Only', src: '/architecture-snowflake.html' };
  const diagrams = isAws ? [awsDiagram, sfDiagram] : [sfDiagram, awsDiagram];
  const kpiVal = (title: string) => data?.kpiCards.find((card) => card.title === title)?.value ?? 'Unavailable';
  const executive = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {['Traceability to Plot', 'FFB Deliveries', 'FFB Intake (kt)', 'Flag Precision'].map((title) => (
          <KPICard key={title} title={title} value={kpiVal(title)} status="neutral" />
        ))}
      </div>
      <p className="text-sm text-slate-600">Traceability to plot = FFB tonnes traced to a geolocated plot / FFB intake tonnes. Flag precision = confirmed canopy-loss cases / screening flags. Volumes are tonnes of fresh fruit bunches (FFB). Screening results are demo signals, not compliance verdicts.</p>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart data={data?.timeseries ?? []} type="line" xKey="period"
          yKeys={[{ key: 'deliveries', name: 'FFB deliveries' }, { key: 'flags', name: 'Screening flags' }]} title="Daily FFB Deliveries and Screening Flags" />
        <Chart data={data?.categories ?? []} type="bar" xKey="category"
          yKeys={[{ key: 'flags', name: 'Flags' }, { key: 'confirmed', name: 'Confirmed canopy loss' }]} title="Screening Flags and Confirmed Canopy-Loss Cases by Risk Signal" />
      </div>
      <DataTable columns={[
        { key: 'id', header: 'Supply base' }, { key: 'region', header: 'City' }, { key: 'category', header: 'Supplier type' },
        { key: 'deliveries', header: 'Deliveries' }, { key: 'traceability', header: 'Traced to plot (%)' }, { key: 'tracedKt', header: 'Traced (kt)' },
        { key: 'flags', header: 'Flags' }, { key: 'confirmed', header: 'Confirmed' }, { key: 'precision', header: 'Precision (%)' },
      ]} data={data?.entities ?? []} title="Supply base observations" />
    </div>
  );
  const predictive = (
    <div className="space-y-4">
      <h2 className="font-semibold">7-day canopy-loss risk and FFB delivery forecast</h2>
      <p className="text-sm text-slate-600">
        Snowflake ML classification predicts the probability that a supply base has a confirmed canopy-loss case in the next 7 days,
        from geolocation mismatch rates, the share of intake from unmapped plots, recent confirmed cases, risk tier, years in the traceability programme and supplier type.
      </p>
      {data?.holdout ? (
        <p role="status" className="text-sm text-slate-700">
          Out-of-time holdout ({data.holdout.n} base-days): precision {pct(data.holdout.precision)} and recall{' '}
          {pct(data.holdout.recall)} at a 0.5 threshold, versus a {pct(data.holdout.baseRate)} base rate.
        </p>
      ) : (
        <p role="status">Model outputs are not deployed. Run snowflake/05_ml.sql.</p>
      )}
      <DataTable columns={[
        { key: 'id', header: 'Supply base' }, { key: 'band', header: 'Risk band' },
        { key: 'probability', header: 'P(canopy loss in 7 days)' }, { key: 'scoredAsOf', header: 'Scored as of' },
      ]} data={data?.risk ?? []} title="Canopy-loss risk by supply base" />
      <Chart data={data?.forecast ?? []} type="line" xKey="period"
        yKeys={[{ key: 'value', name: 'Forecast' }, { key: 'lower', name: 'Lower' }, { key: 'upper', name: 'Upper' }]}
        title="Network-wide FFB delivery forecast, next 14 days (deliveries per day)" />
      <DataTable columns={[
        { key: 'id', header: 'Supply base' }, { key: 'date', header: 'Date' }, { key: 'mismatch', header: 'Geolocation mismatch (%)' },
        { key: 'expected', header: 'Expected' }, { key: 'upper', header: 'Upper bound' },
      ]} data={data?.anomalies ?? []} title="Geolocation mismatch anomalies, last 15 days (Snowflake ML anomaly detection, trained on the prior 75 days)" />
    </div>
  );
  const liveTab = (
    <div className="space-y-4">
      <h2 className="font-semibold">{isAws ? 'Live deliveries: S3 upload to Snowpipe' : 'Live deliveries: Snowflake-native simulator'}</h2>
      <p className="text-sm text-slate-600">
        {isAws
          ? 'Simulated mill-gate FFB delivery events are uploaded to the S3 landing bucket under deliveries/ (aws/publish_deliveries.py), and Snowpipe auto-ingest loads them into RAW.LIVE_DELIVERIES.'
          : 'CALL APP.SIMULATE_DELIVERIES(n) inserts simulated mill-gate FFB delivery events directly into RAW.LIVE_DELIVERIES (or resume APP.TASK_SIMULATE_DELIVERIES for a feed every minute). This simulates a mill weighbridge feed; it is not Snowpipe Streaming.'}
        {' '}A FLAG event is a delivery ticket without a matching geolocated plot. The alert APP.LIVE_DELIVERY_ALERT logs FLAG events and emails the traceability team.
      </p>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard title="Delivery events loaded" value={String(data?.liveSummary?.n ?? 'n/a')} />
        <KPICard title="FLAG events" value={String(data?.liveSummary?.flags ?? 'n/a')} />
        <KPICard title={isAws ? 'Median send to table lag (s)' : 'Median generated to table lag (s)'} value={String(data?.liveSummary?.medianLagSeconds ?? 'n/a')} />
        <KPICard title="Last load" value={data?.liveSummary?.lastLoaded ?? 'none'} />
      </div>
      <DataTable columns={[
        { key: 'id', header: 'Supply base' }, { key: 'eventTs', header: 'Event (UTC)' }, { key: 'tonnes', header: 'FFB (t)' },
        { key: 'mismatch', header: 'Geo mismatch (%)' }, { key: 'status', header: 'Status' }, { key: 'loadedAt', header: 'Loaded' },
      ]} data={data?.live ?? []} title="Latest 25 delivery events" />
      <DataTable columns={[
        { key: 'id', header: 'Supply base' }, { key: 'eventTs', header: 'Event (UTC)' }, { key: 'tonnes', header: 'FFB (t)' },
        { key: 'mismatch', header: 'Geo mismatch (%)' }, { key: 'hint', header: 'Action hint' },
      ]} data={data?.alerts ?? []} title="Traceability alert log" />
    </div>
  );
  const planning = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KPICard title="Supplier Declaration Rate" value={kpiVal('Supplier Declaration Rate')} />
        <KPICard title="Plot Geolocation Coverage" value={kpiVal('Plot Geolocation Coverage')} />
        <KPICard title="Geolocation Checks Pending" value={kpiVal('Geolocation Checks Pending')} />
      </div>
      <Chart data={data?.declarationRisk ?? []} type="scatter" xKey="compliance" xName="Declaration rate"
        yKeys={[{ key: 'confirmed', name: 'Confirmed canopy-loss cases' }]} yDomain={[0, 'auto']}
        title="Supplier declaration rate (%) vs confirmed canopy-loss cases by supply base" />
      <p className="text-sm text-slate-600">Synthetic associations are not evidence that declarations prevented deforestation.</p>
      <ActionMemo persona={{ name: 'Dewi Lestari', role: 'Head of Sustainability (fictional persona)' }} context={{}}
        onGenerate={async () => {
          const r = await fetch('/api/ask', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ mode: 'memo' }) });
          if (!r.ok) throw new Error('memo failed');
          const j = await r.json();
          return { subject: 'Draft traceability follow-up actions (synthetic data, human review required)', body: j.answer, urgency: 'review', actions: [] };
        }} />
      <p role="status" className="text-sm text-slate-600">{isAws ? 'Draft generated by Amazon Bedrock (Claude) through a Snowflake external-access function' : 'Draft generated by Snowflake Cortex AI_COMPLETE (Claude Sonnet 4.5)'}, from the KPI, supply base, risk-signal and risk tables only. No notification is sent.</p>
    </div>
  );
  const ai = (
    <div className="space-y-4">
      <p role="status">Answers come from the Cortex Agent APP.EUDR_AGENT. It uses Cortex Analyst over the semantic view APP.EUDR_ANALYTICS for metrics, and Cortex Search over synthetic traceability follow-up SOPs for procedures. The generated SQL is shown with each answer.</p>
      <div className="h-[500px]">
        <AskAI title="Ask the traceability agent" mode="advisor" sampleQuestions={['Which 3 supply bases have the most confirmed canopy-loss cases?', 'Which supply bases are high risk this week and what SOP applies?', 'What is traceability to plot by supplier type?']}
          onSubmit={async (question) => {
            const r = await fetch('/api/agent', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ question }) });
            if (!r.ok) throw new Error('agent failed');
            const j = await r.json();
            const cites = j.sops?.length ? `\n\nSOPs: ${j.sops.join(', ')}` : '';
            return { answer: `${j.answer}${cites}`, sql: j.sql ?? undefined };
          }} />
      </div>
    </div>
  );
  const architecture = (
    <div className="space-y-4">
      {diagrams.map((d, i) => (
        <div key={d.key} className="space-y-2">
          <h2 className="font-semibold">Architecture: {d.title}{i === 0 ? ' (this deployment)' : ''}</h2>
          <iframe src={d.src} title={`${d.title} architecture diagram`} className="h-[620px] w-full rounded border border-slate-200" />
          <p className="text-sm text-slate-600">Hover a component for details. <a className="underline" href={d.src} target="_blank" rel="noreferrer">Open full screen</a></p>
        </div>
      ))}
      <h2 className="font-semibold">Implementation status</h2>
      <p>Core source: synthetic supply bases (8 Indonesian mill-hub cities x 5 supplier types), daily mill-intake observations and a plot registry. Curated dynamic tables compute numerator/denominator metrics and are suspended after on-demand initialization.</p>
      <p>Application: Next.js server queries the explicit curated contract. Request time and source observation watermark are separate.</p>
      <p>ML: SNOWFLAKE.ML.CLASSIFICATION canopy-loss risk model evaluated on a time-based holdout, plus a 14-day FFB delivery FORECAST with prediction intervals.</p>
      <p>ML: ANOMALY_DETECTION flags geolocation mismatch outliers per supply base over the last 15 days.</p>
      <p>AI: Cortex Agent (Cortex Analyst over a semantic view, plus Cortex Search over SOPs) answers questions. The action memo uses {isAws ? 'Amazon Bedrock Claude through an external-access UDF' : 'Cortex AI_COMPLETE (Claude Sonnet 4.5)'}.</p>
      {isAws ? (
        <>
          <p>AWS ingestion: FFB delivery batches uploaded to S3, then Snowpipe auto-ingest (SQS) into RAW.LIVE_DELIVERIES, with a Snowflake alert and email on FLAG events.</p>
          <p>QuickSight: Snowflake DIRECT_QUERY dashboard (daily deliveries, confirmed canopy-loss cases by supply base, canopy-loss risk), with a Q topic.</p>
        </>
      ) : (
        <>
          <p>Ingestion: APP.SIMULATE_DELIVERIES inserts simulated FFB delivery events into RAW.LIVE_DELIVERIES, with a Snowflake alert and email on FLAG events. No AWS account is used.</p>
          <p>BI: this SPCS app is the dashboard; natural-language questions go to the Cortex Agent.</p>
        </>
      )}
      <p>Orchestration: the task graph APP.TASK_REFRESH_CURATED, then TASK_RESCORE_RISK, runs on demand. Alerts and tasks stay suspended between demos.</p>
    </div>
  );
  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '', content: executive },
    { id: 'predictive', label: 'Predictive', icon: '', content: predictive },
    { id: 'planning', label: 'Plot Registry', icon: '', content: planning },
    { id: 'live', label: 'Live Deliveries', icon: '', content: liveTab },
    { id: 'ask-ai', label: 'Ask AI', icon: '', content: ai },
    { id: 'architecture', label: 'Architecture & Data', icon: '', content: architecture },
  ].map((tab) => ({ ...tab, content: tab.id === 'architecture' ? tab.content : (
    <div className="space-y-4">
      <p className="text-sm text-slate-600">Synthetic demo data for a fictional palm oil supplier network. On-demand snapshots are not live operations, and screening results are not compliance verdicts.</p>
      {loading ? <p role="status">Loading Snowflake data...</p> : error ? (
        <div role="alert" className="rounded border border-red-200 p-4">
          <p>{error}</p>
          <button className="mt-3 rounded border px-3 py-2" onClick={() => setAttempt((value) => value + 1)}>Retry data connection</button>
        </div>
      ) : !data?.entities.length ? <p role="status">No supply base observations are available in this snapshot.</p> : (
        <>
          <p className="text-sm">Observation watermark: {data.sourceWatermark ?? 'Unavailable'}. Request time: {data.requestedAt}.</p>
          {(data.stale || data.pipelineBehind) && <p role="status" className="text-amber-700">Stale or lagging snapshot. Refresh the on-demand pipeline before presenting current results.</p>}
          {tab.content}
        </>
      )}
    </div>
  ) }));
  return <AppLayout title="Indonesia Palm Oil EUDR Readiness" tabs={tabs} />;
}
