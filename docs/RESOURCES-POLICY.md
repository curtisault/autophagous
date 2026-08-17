# The Source Index

Goal: every citation in the protocol resolves to the best copy a
reader can legally reach, and none of it is rehosted here.

*(Renamed and rewritten 2026-08-16, owner's decision. This doc was
`RESOURCES-ARCHIVE.md` and described a local PDF archive under
`public/resources/pdf/`. That plan is retired — see "Why not an
archive" below. The old slugs survive; nothing else of the archive
does.)*

## The position

**Link, never rehost.** Each entry carries a DOI (where the work has
one) and, where a free copy exists somewhere other than the DOI target,
a direct link to it. No PDF is served from this repository.

The manifest in `src/Page/Resources.elm` is the single source of truth
for citation metadata and access state.

## Why not an archive

Two reasons, in order of weight:

1. **Read access is not redistribution permission.** The archive plan
   assumed that finding a free PDF on PMC meant it could be rehosted.
   It does not: NIH public-access manuscripts are deposited under terms
   that permit public access *on PMC*, which is not a licence for a
   third party to serve copies. Of the 19 entries, only three are under
   an open licence (`Open` in the manifest) and would ever have been
   ours to serve. The rest would have required a per-entry licence
   audit to publish anything at all — recurring work, with real
   downside if it were ever done carelessly.

2. **A frozen copy cannot report its own corrections.** A DOI always
   resolves to the current state of the record; a stored PDF is the
   paper as it was on the day it was fetched. Two entries in this list
   have published corrections (#15's corrigendum and #19's correction).
   On a site whose citations back safety claims, silently serving a
   stale copy of a corrected paper is a worse failure than a
   click-through.

Link rot — the archive's original motivation — is what DOIs exist to
solve. They survive publisher migrations by design, which was the
stated fear.

## Access states

The `Access` type in the manifest. Every state was set from an
Unpaywall query against the entry's DOI, checked 2026-08-16.

| State | Means | Reader gets |
|---|---|---|
| `Open license` | Version of record under an open licence (gold/hybrid OA) | The DOI lands on free full text |
| `FreeAtPublisher` | Readable at the publisher, no open licence ("bronze") | The DOI lands on free full text — but this can be withdrawn without notice |
| `Manuscript url` | A free repository copy (PMC, institutional) | A direct link, usually the author manuscript rather than the typeset paper |
| `Web url` | A free document with no DOI (prize citation, society guidance) | A direct link to its own page |
| `Paywalled` | No free copy exists | The DOI, and a mark saying so honestly |

The distinction between `Open` and `FreeAtPublisher` is the whole
argument on this page: both are free to read today, only one is
licensed. Do not collapse them.

## Slugs

Slugs are `<first-author>-<keyword>-<year>`, lowercase, hyphenated, and
stable forever once assigned. They were reserved as PDF paths; they now
serve as **per-entry anchors** — `/resources#<slug>` is a permanent
public address for a single citation, which is the promise the slugs
were always making. The protocol can deep-link a specific source.

## Adding or correcting an entry

1. **Get the DOI from CrossRef, and verify it.** Match on title *and*
   journal *and* volume *and* page range before accepting one. A title
   query alone returns commentaries, corrigenda, conference abstracts,
   and H1 Connect recommendation records ahead of the paper — this bit
   us on #8, #15 and #16 during the 2026-08-16 backfill.
2. **Set the access state from Unpaywall**, not by assumption:
   `https://api.unpaywall.org/v2/<doi>?email=<you>`. Map `oa_status`
   gold/hybrid → `Open`, bronze → `FreeAtPublisher`, green →
   `Manuscript` with `best_oa_location.url`, closed → `Paywalled`.
3. **Check the link resolves** before committing it.
4. If a work carries a correction or corrigendum, say so in the
   citation string — see #15 and #19 for the form.

Entries without a DOI (#2, a Nobel prize citation; #18, ASA guidance)
are `Web` entries. That is correct, not an omission: neither is a
journal article and neither has a DOI to carry.

## Still worth doing

Snapshot each source's landing page to the Internet Archive
(`https://web.archive.org/save/<url>`) as a second line of defence.
That is hosting by the Internet Archive, not by us, so it raises none
of the questions above. The manifest can grow an `archiveOrgUrl` field
when we start recording them.
