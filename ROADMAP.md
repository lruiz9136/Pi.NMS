# Pi.NMS Roadmap

This roadmap tracks the fork's transition from Pi.Alert-style discovery into a
small-network NMS.

## Phase 1: Cleanup and Identity

- Rename visible product references from Pi.Alert to Pi.NMS.
- Update README and docs to explain the NMS direction.
- Keep legacy file names and install paths stable until migration scripts exist.
- Point project links at the Pi.NMS fork.

## Phase 2: Inventory Foundation

- Introduce a node-oriented inventory model.
- Add tags, owner, location, role, and notes to monitored assets.
- Separate discovered devices from managed nodes.

## Phase 3: Checks and Status

- Add ICMP, TCP, HTTP, and DNS checks.
- Store check results separately from discovery events.
- Add status states: up, down, warning, unknown, maintenance, and ignored.

## Phase 4: Events and Incidents

- Normalize raw events.
- Group repeated failures into active incidents.
- Add acknowledgement and maintenance workflows.

## Phase 5: NMS Views

- Build dashboard views for active incidents, down nodes, warnings, and recent
  network changes.
- Add subnet and topology-oriented views.
- Expand notification rules by severity, group, and check type.