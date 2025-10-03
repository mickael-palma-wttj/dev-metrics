I want to create a cli application that can get these developer metrics :
| Category                               | Metric                                       | Source                        | How to compute                          | What it tells you                                      |
| -------------------------------------- | -------------------------------------------- | ----------------------------- | --------------------------------------- | ------------------------------------------------------ |
| **Commit Activity**                    | Commits per developer (per week/month)       | git log                       | `git shortlog -s -n --all`              | Raw activity level; throughput baseline                |
|                                        | Commit size (added+deleted LOC per commit)   | git log                       | `git log --numstat`                     | Batch size discipline (small commits easier to review) |
|                                        | Commit frequency distribution                | git log                       | Count per day/hour                      | Working patterns, flow                                 |
|                                        | Lines added/removed/net                      | git log                       | `git log --numstat` by author           | Volume proxy, churn indicator                          |
| **Code Churn & Ownership**             | Churn per file (added+deleted LOC)           | git log                       | Aggregate `numstat` per file            | Hotspots (risky areas)                                 |
|                                        | Authors per file                             | git log                       | Distinct authors from `git log -- file` | Bus factor, shared ownership                           |
|                                        | Top last-touch owner per file                | git log                       | Last commit author                      | Code ownership concentration                           |
|                                        | Co-change file pairs                         | git log                       | Files modified together in commits      | Coupling, modularity issues                            |
| **Reliability / Quality Proxies**      | Revert commits rate                          | git log                       | grep "revert" in subjects               | Instability proxy                                      |
|                                        | Bugfix-ish commit ratio                      | git log                       | grep "fix | bug | issue"                | Defect-fix proxy                                       |
|                                        | Large commit frequency                       | git log                       | Commit size > threshold                 | Risky changes                                          |
| **Flow / Delivery**                    | Lead time commit→tag                         | git log                       | commit authorDate vs tagDate            | Approx DORA Lead Time                                  |
|                                        | Deployment frequency                         | git log / GitHub API          | tags per period / releases API          | DORA Deployment Frequency                              |
| **PR Throughput**                      | PRs opened/merged per dev                    | GitHub API                    | `pullRequests` query                    | Delivery velocity                                      |
|                                        | PR size (churn, files, commits)              | GitHub API                    | additions+deletions+files               | Batch size / reviewability                             |
|                                        | Time to first review                         | GitHub API                    | createdAt→first reviewAt                | Review responsiveness                                  |
|                                        | Time to first approval                       | GitHub API                    | createdAt→approvalAt                    | Review turnaround                                      |
|                                        | PR open time                                 | GitHub API                    | createdAt→mergedAt/closedAt             | Cycle time                                             |
|                                        | Approval→merge time                          | GitHub API                    | approvalAt→mergedAt                     | Post-approval friction                                 |
|                                        | Review rounds                                | GitHub API + commits          | CHANGES_REQUESTED→commit→review cycle   | Rework / clarity issues                                |
|                                        | Draft→ready conversion time                  | GitHub API                    | draft creation→readyForReviewAt         | Grooming quality                                       |
| **Review Collaboration**               | Reviews given per dev                        | GitHub API                    | `reviews` query                         | Reviewer load                                          |
|                                        | Median review response time (working hours)  | GitHub API                    | PR createdAt→reviewAt                   | Reviewer responsiveness                                |
|                                        | % reviews with comments                      | GitHub API                    | comments.totalCount>0                   | Review depth vs rubber-stamping                        |
|                                        | % changes requested                          | GitHub API                    | reviews with state=CHANGES_REQUESTED    | Assertiveness on quality                               |
|                                        | Unique reviewers per PR                      | GitHub API                    | distinct review authors                 | Review coverage                                        |
|                                        | Review coverage ratio                        | GitHub API                    | reviews given / PRs needing review      | Cross-team collaboration                               |
| **Knowledge / Ownership**              | PRs across repos/modules                     | GitHub API                    | count per repo/path                     | Breadth vs specialization                              |
|                                        | Critical file PRs                            | git log + PRs                 | intersection hotspots × PR author       | Contribution in high-risk code                         |
| **Team Health**                        | Off-hours commits                            | git log                       | commit timestamps outside 9–18h         | Overload / burnout risk                                |
|                                        | Off-hours reviews                            | GitHub API                    | review timestamps                       | Same as above                                          |
|                                        | Pickup gap (created→first human interaction) | GitHub API                    | createdAt→first review/comment          | SLA on PRs                                             |
| **Quality / Stability (needs enrich)** | Change Failure Rate                          | GitHub API + issues           | % PRs followed by “fix/revert”          | Approx DORA Change Failure Rate                        |
|                                        | MTTR                                         | GitHub API + incidents/issues | time bug opened→fix merged              | DORA MTTR                                              |

I want a Ruby application using only standard libraries and rspec.

Respect best practices from ./ruby-refactoring.prompt file

I want every "metric" in the same lib/metrics/* folder, one file per metric
I want to clearly seperate "git log" metrics from "GitHub API" metrics.
I want to be able to specify a path and the app should detect "git" compatible folder and prompt me to select the repository I want to analyze
I want the data scoped by repository and I also want aggregated report for each