claude mcp remove --scope user context7
claude mcp add    --scope user context7 -- npx -y @upstash/context7-mcp@latest
claude mcp remove --scope user playwright
claude mcp add    --scope user playwright -- npx @playwright/mcp@latest --cdp-endpoint http://localhost:9222
