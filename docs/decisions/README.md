# Decisions

Architecture decision records for this repo: one file per decision, in
[MADR 4.0](https://adr.github.io/madr/) format. Before changing something a
record covers, read the record, whether you are a person or an agent. How
records are kept is [ADR-0000](0000-record-decisions-in-madr.md).

Questions nobody has decided yet are in
[`../decision-backlog/`](../decision-backlog/README.md), not here.

## Records

| ADR | Decision | Status |
|---|---|---|
| [0000](0000-record-decisions-in-madr.md) | Record decisions as MADR 4.0 Bare Minimal files, with a backlog beside them | accepted |
| [0001](0001-static-web-app-free-tier-with-named-environment.md) | Host on a Free-tier Azure Static Web App, with a named environment for a readable URL | accepted |

## Adding one

1. Copy [adr-template.md](adr-template.md) to `NNNN-title-with-dashes.md`,
   using the next free number.
2. Fill in `status`, `date` and `decision-makers` in the front matter.
3. Write the four sections, and add a row to the table above.

To change a decision, check with its decision-makers first, then change its
record in place. Git history keeps the earlier wording. If a new record
replaces an old one, set the old one's status to `superseded by ADR-NNNN`.
