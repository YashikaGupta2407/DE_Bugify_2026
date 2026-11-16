# Problem understanding

| Problem | Business need and affected stakeholders | Class | Assumptions |
|---|---|---|---|
| P1 | Load Continue Watching, Top 10, My List and genre rows quickly for members and personalization/UI teams. | Customer-facing, real-time | Home-screen reads have interactive latency targets. |
| P2 | Open title pages, find/search titles and start the next episode without playback delay. Affected members and Playback/Search. | Customer-facing, real-time | Search and playback operations are interactive. |
| P3 | Authenticate despite email case differences and switch profiles quickly. Affected members, Identity and support. | Customer-facing, real-time | Email matching is case-insensitive at the application/query layer. |
| P4 | Identify episodes with no viewing activity so Content Strategy can evaluate catalogue performance. | Reporting, analytics | An episode counts as watched when a viewing row references its episode ID. |
| P5 | Produce retry, on-hold, billing and dunning lists promptly. Affected members, Payments and Billing. | Reporting, analytics | Billing changes and monthly runs must also preserve transactional correctness. |
| P6 | Detect kids profiles viewing above their maturity limit and accounts with concurrent household streams beyond plan limits. Affected kids, parents and Compliance/Trust. | Reporting, analytics | This workload is retrospective detection; policy enforcement also belongs in application logic. |
| P7 | Run binge, completion, device, originals, ratings and My List analytics as view volume grows. Affected Content Analytics and members through recommendations. | Reporting, analytics | The expected growth is 20 times current viewing data. |
| P8 | Report plan revenue and churn and provide a fast activity console. Affected Finance and Support. | Reporting, analytics for finance; customer-facing operational reads for support | The activity console is used interactively; the finance reports can run asynchronously. |

The supplied workload contains reads and writes. The classification above describes the business purpose, not whether a specific SQL statement is technically a read or write. The 20× growth statement is treated as a capacity planning assumption supplied by the project brief.
