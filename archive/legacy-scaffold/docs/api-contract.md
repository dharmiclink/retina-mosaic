# API Contract Notes

- REST contract source: `packages/contracts/openapi.yaml`
- WS event contract source: `packages/contracts/ws-events.ts`
- Initial implementation in `apps/api/app/routes` and `apps/api/app/ws`.

## Versioning strategy

- Prefix all API routes with `/v1`.
- Add new response fields as additive changes.
- Keep websocket events backward compatible per event type.
