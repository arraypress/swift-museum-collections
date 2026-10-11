# Swift Museum Collections

The open collections of the Metropolitan Museum of Art and the Art Institute of Chicago as one typed, keyless library.

```swift
import MuseumCollections

let museums = MuseumCollections()
let results = try await museums.search(ArtworkQuery("sunflowers", publicDomainOnly: true, limit: 6))
for work in results.artworks { print(work.id, work.title, work.artist ?? "") }
// met:436524  Sunflowers  Vincent van Gogh
// aic:35720   Sunflowers  Georges Lemmen …

let wheat = try await museums.artwork(ArtworkID("met:436535")!)
let saved = try await museums.download(ArtworkID("aic:27992")!, to: URL(fileURLWithPath: "."), width: 1200)
```

## Features

- 🖼️ **One artwork model** — title, artist and their dates, the date text and the span of years it covers (BCE negative), medium, dimensions, department, type, origin, credit line, rights, image and page — whichever museum it came from
- 🔀 **One search over both** — the museums are asked at once and their rankings interleaved (first of each, then second of each), so neither is ranked against the other's scale. A museum that fails is reported in `failures` while the other's results still come back
- 🪪 **Ids that carry their museum** — `met:436524`, `aic:27992`, or either museum's page URL; a bare number is refused
- ⚖️ **Rights respected** — `download` saves public-domain images only; anything else throws `notPublicDomain` unless the caller passes `allowRestricted`, and Chicago's restricted images are never asked for wider than the 843 pixels it serves
- 📐 **Sizes** — exact widths through Chicago's IIIF server; the Met's web image (up to 1,000) or its original
- 📄 **Paging that tells the truth** — `next` gives, per museum, the offset that continues it
- 🧵 **Modern Swift** — async/await throughout, every model `Sendable`, typed throws (`throws(MuseumError)`) on the public API, the Met's reads in a bounded task group (eight in flight, results in order, the first error or a cancellation stops the rest)
- 🧪 **Tested without a network** — an injectable `Transport`; 29 tests, five of them live (skipped, not failed, when a museum refuses)

## What the APIs do that you would not guess (all measured, October 2026)

- **The Met's search returns ids only.** Every result is a second request. They are read eight at a time, and a page of `limit` reads at most `4 × limit + 10` objects.
- **The Met ignores `isPublicDomain`.** "sunflowers" counted 178 with and without it, so the filter is applied after reading. Its works that are not public domain come back with *empty-string* image fields — they have no image here, which is why a default (images-only) Met search returns only public-domain works.
- **The Met retired its v1 search on 2026-10-01** (HTTP 410). This uses v1.1, which pages with `offset`/`limit` (at most 500).
- **Chicago scores every artwork for every query.** "zzqqxxnothing" matched all 133,165, and "the" (a stop word) scored everything about 0.00002. Real matches scored 5 to 3,995; anything under 1 is dropped. Its reported total is therefore meaningless and is not passed on.
- **Chicago's image server needs `AIC-User-Agent`.** Measured 403 with only `User-Agent`, 200 with both, so every `artic.edu` request carries it.
- **Chicago serves restricted works at 843 pixels at most** (1,686 redirected); public-domain works at any width. It pages no further than result 10,000.
- **`artist_display` comes in two shapes:** "Georges Seurat (French, 1859–1891)" and "Katsushika Hokusai 葛飾 北斎\nJapanese, 1760-1849". Both are split into name and details.

## Measured

Release build, a home connection, three runs each, 10 results:

| Search | Time | Objects read |
|---|---|---|
| Met, "sunflowers" | 3.7–4.2 s | 23 (13 had no shared image) |
| Met, "portrait", public domain | 2.8–3.0 s | 18 |
| Chicago, "cat" | 0.8–1.6 s | — (one request) |
| Both, "cat" | 2.6–3.0 s | — |

Read one at a time, a Met object took about a second, so eight at once is what makes the Met usable. A Met original (Van Gogh's *Sunflowers*) is 6.1 MB and took 4.7 s; Chicago's IIIF at 1,200 pixels returned exactly 1,200 wide.

Live edge cases, all checked: nonsense finds nothing in either museum; unknown ids throw `notFound` from both; Unicode names search in both (葛飾北斎 finds Hokusai at the Met and in Chicago, Dürer in Chicago); BCE ranges filter both (600–300 BCE amphorae); works without a shared image have `image == nil`.

## Requirements

macOS 14+ / iOS 16+ / tvOS 16+ / watchOS 9+ / visionOS 1+, Swift 6.2 tools, Swift 6 language mode with `NonisolatedNonsendingByDefault`. Foundation only. No key: both APIs are open (the Met's data is CC0; Chicago's is CC0 apart from descriptions, which this does not fetch).

## License

MIT — see LICENSE.
