# The Resources Archive

Goal: every citation in the protocol lives on as a locally-archived
PDF, immune to link rot, publisher migrations, and dead DOIs.

## Layout

```
public/resources/pdf/<slug>.pdf   — the archived documents (deployed)
src/Page/Resources.elm            — the manifest (single source of truth)
```

Slugs: `<first-author>-<keyword>-<year>`, lowercase, hyphenated,
stable forever once assigned (they are public URLs). The 19 slugs are
already reserved in the manifest.

## Acquisition, per entry (in order of preference)

1. **Publisher/journal open access** — several citations are OA
   (PLoS ONE #5, JAHA #4, the Klionsky guidelines #1, the Nobel
   citation #2, ASA guidance #18): download the version of record.
2. **PubMed Central** — most NIH-funded papers (#3, #6, #7, #8, #13,
   #14, #15) have a free PMC author manuscript or VoR.
3. **Unpaywall / DOI resolution** — for the rest, check
   `https://api.unpaywall.org/v2/<doi>` for a legal OA location.
4. **Author preprint / institutional repository.**
5. If none exists, the entry keeps its DOI link and stays
   "not yet archived" — do not archive pirated copies.

A practical workflow: manage the collection in **Zotero** (it fetches
OA PDFs automatically and stores clean metadata), then export PDFs
into `public/resources/pdf/` under the reserved slugs.

## Licensing rule

Only redistribute what the license permits (CC-BY and similar OA
licenses, US-government works, publisher-permitted author
manuscripts). Paywalled works without a redistributable version are
*linked*, not served — a personal research copy may live outside
`public/` (e.g. an untracked `archive-private/`), but never ships.

Additionally, snapshot each source's landing page to the Internet
Archive (https://web.archive.org/save/<url>) as a second line of
defense; the manifest can grow an `archiveOrgUrl` field when we start
recording those.

## Flipping an entry to archived

1. Drop the PDF at the reserved path.
2. Set `archived = True` (and add the DOI if it was missing) in
   `src/Page/Resources.elm`.
3. Both in one commit, so the manifest never lies.
