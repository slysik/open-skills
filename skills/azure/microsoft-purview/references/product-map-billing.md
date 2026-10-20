# Purview: product map, renames and billing

Last verified: 2026-10-20. Source: Microsoft Learn `purview/purview` (2026-06-26), `purview-portal` (2026-08-05), `unified-catalog` (2026-03-16), `data-map`, `data-governance-billing` (2026-04-24), `purview-billing-models` (2026-06-15), `purview-compliance`, `purview-security`. GA/PREVIEW tags are only those the pages state; otherwise `UNVERIFIED`.

## 1. Portal and naming
- Unified portal: `purview.microsoft.com`. Solutions grouped as **Data Security**, **Data Governance**, **Data Compliance**.
- Retired: the compliance portal and the **classic Microsoft Purview governance portal**. Classic Data Catalog stays usable without consenting to the new billing model; classic Data Catalog, Data Health Insights and Workflow are in customer-support mode and no longer take new customers.
- Renames: Classification is now **Classifiers**; Data Estate Insights is now **Reports** (Unified Catalog, Health management, Reports); glossary moved to Unified Catalog, Discovery, Enterprise glossary; data asset search moved to Unified Catalog, Discovery, Data assets; Microsoft Information Protection is now **Microsoft Purview Information Protection**; Privacy Risk Management moved to Microsoft Priva; Content Search is core to eDiscovery.
- The Unified Catalog experience is "rolling out across environments" per its page: verify your tenant has it.

## 2. Solution map
| Area | Components | Customer question it answers |
|---|---|---|
| **Data governance** | Data Map (foundation: scans, classification, lineage), Unified Catalog (governance domains, data products, glossary terms, OKRs, critical data elements, data quality, health management, access policies) | What data do we have, who owns it, can we trust it? |
| **Data security** | Information Protection (labels), DLP, Insider Risk Management, Information Barriers, Privileged Access Management, Data Security Investigations, DSPM (described as "Now in preview" on the overview) | Is sensitive data protected and who is misusing it? |
| **Data compliance** | Audit, Communication Compliance, Compliance Manager, Data Lifecycle Management, eDiscovery, Records Management | Can we prove and retain what regulators ask? |

Data Map vs Unified Catalog: assets must be **scanned into the Data Map** first. Unified Catalog "currently runs on the existing Data Map" and its permissions layer on top of Data Map permissions.

## 3. Free vs enterprise
Free version is limited to "Catalog" and "Data Map history". Upgrade to enterprise for governance features. Unified Catalog capabilities listed: access policies, critical data elements (Preview), glossary terms (classic glossary migration is Preview), governance domains, data products, health actions (Preview), health controls, data quality, OKRs (Preview), search and self-service access requests.

## 4. Billing meters (verify against the Azure pricing page; figures not rendered there)
| Meter | Unit | Notes |
|---|---|---|
| Unified Catalog governed assets | Unique governed assets per day | Only tables and views linked to governance concepts count; assets only in Data Map do not; an asset counts once per day |
| Data health and data quality compute | **DGPU** (Data Governance Processing Unit), 1 DGPU = 60 minutes of compute; SKUs Basic (default), Standard, Advanced | Example on billing page: Azure SQL 1M rows, Basic, empty-check rule = 0.02 DGPU per rule per run; health controls run daily at Basic |
| Data Map (classic accounts) | Capacity units billed hourly | 1 CU = 25 operations/s and 10 GB metadata; start at 1 CU, autoscale to 10 CU default; Data Map and scan charges do not apply to Unified Catalog customers after consent or upgrade to enterprise |
| Managed VNet IR | 1/8 vCore-hour per hour of uptime plus scan runs | See scanning reference |
| Pay-as-you-go since 2025-01-06 | Governance billing | Per-user licensing remains for M365 and Windows/macOS |
| Other pay-as-you-go | Information Protection: assets in scope per day; Insider Risk: data security processing units (1 per 10,000 activities); Communication Compliance: text records (1,000 chars each); Audit: audit records; eDiscovery: GB stored per day; Security Copilot: SCUs | |

Price points (for example a per-asset-per-day rate or DGPU prices) are `UNVERIFIED`: the pricing page did not render numbers. Do not quote dollar figures; run the Azure pricing calculator.

## 5. PoC sizing mistakes
- Scanning everything instead of the sources behind 2 to 3 data products (billing counts governed assets, and scans cost time).
- Running data quality scans on large tables at Advanced SKU "to be safe".
- Forgetting the E5-type licences or pay-as-you-go prerequisites for the security features (licence detail `UNVERIFIED`; the service description page was not read).
- Starting without owners, then discovering nobody can approve a data product.

## 6. Talk track
"Purview bills catalog work by governed assets and data quality by processing units, not by how many sources you scan, so we scope the PoC to a few data products and measure DGPU for a week before extrapolating."
