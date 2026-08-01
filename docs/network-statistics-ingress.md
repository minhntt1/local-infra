# network-statistics Ingress Routing

## Overview

Traefik routes external HTTP traffic to the network-statistics admin service. The admin service runs a Spring Boot application that serves Thymeleaf templates, REST endpoints, and static assets (CSS, JS).

## Path Separation

Prod and dev are accessed via different URL prefixes on the same Traefik entry point (`10.10.0.5:80`):

| Environment | External URL                           | Traefik rule                    | Spring context-path          |
|-------------|----------------------------------------|---------------------------------|------------------------------|
| Prod        | `http://10.10.0.5/prod/network-statistics/...` | `PathPrefix(/prod/network-statistics)` | `/prod/network-statistics`   |
| Dev         | `http://10.10.0.5/dev/network-statistics/...`  | `PathPrefix(/dev/network-statistics)`  | `/dev/network-statistics`    |

Traefik forwards the full path **without stripping the prefix** — the backend Spring Boot handles the prefix via `server.servlet.context-path`.

## Context-Path Configuration

The context-path is set in Spring Boot profile-specific property files:

`application-prd-admin.properties`:
```properties
server.servlet.context-path=/prod/network-statistics
```

`application-dev-admin.properties`:
```properties
server.servlet.context-path=/dev/network-statistics
```

This is configured per-profile so the same JAR can be built once and deployed to either environment.

### Why Context-Path Instead of Traefik stripPrefix?

The Traefik `stripPrefix` middleware strips the path prefix before forwarding to the backend, but this breaks Thymeleaf URL generation:

- `@{/css/style.css}` generates `/css/style.css` (no prefix) → browser requests `http://10.10.0.5/css/style.css`
- This URL doesn't match `PathPrefix(/prod/network-statistics)` → 404

With `server.servlet.context-path`, Thymeleaf automatically prepends the context-path to all `@{...}` expressions, generating correct URLs like `/prod/network-statistics/css/style.css`.

## Template URL Rules

### Thymeleaf Expressions (auto-prepend context-path)

Always prefer these when writing links in templates:

```html
<!-- Link to controller -->
<a th:href="@{/web/client/getList.do}">...</a>

<!-- Form action -->
<form th:action="@{/web/modem/auth/postModemAuthInfo.do}" method="post">

<!-- Static resources -->
<link rel="stylesheet" th:href="@{/css/style.css}">
<script th:src="@{/js/script.js}"></script>
```

### Raw HTML Attributes (do NOT prepend context-path)

The following will **break** with context-path enabled:

```html
<link rel="stylesheet" href="/css/style.css">       <!-- WRONG -->
<script src="/js/script.js"></script>                <!-- WRONG -->
```

### JavaScript Hardcoded URLs

For AJAX `fetch()` calls or `XMLHttpRequest` with hardcoded absolute paths, use the Thymeleaf JavaScript inlining pattern to inject the context-path:

```javascript
<script th:inline="javascript">
function loadData(clientKey, page) {
    var basePath = /*[[@{/}]]*/ '';
    var url = basePath + '/web/client/connection/getInfo.do?clientKey=' + clientKey;
    fetch(url)
        .then(function(r) { return r.text(); })
        .then(function(html) {
            document.getElementById('section').innerHTML = html;
        });
}
</script>
```

The `/*[[@{/}]]*/` syntax is evaluated by Thymeleaf at render time and replaced with the context-path (e.g., `/prod/network-statistics`). The `''` is the static fallback when opening the file directly.

The enclosing `<script>` tag **must** have `th:inline="javascript"` for this to work.

## Checklist: Adding a New Service Behind Traefik

1. In the Helm chart's IngressRoute template, set `PathPrefix(/<env>/<service-name>)`
2. Do **not** add a `stripPrefix` middleware
3. In the Spring Boot profile config, set `server.servlet.context-path=/<env>/<service-name>`
4. In Thymeleaf templates, always use `@{...}` expressions — never raw `href` or `src`
5. For JavaScript AJAX URLs, use the `/*[[@{/}]]*/ basePath pattern` with `th:inline="javascript"`