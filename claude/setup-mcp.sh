claude mcp remove --scope user context7
claude mcp add    --scope user --transport http context7 https://mcp.context7.com/mcp
claude mcp remove --scope user playwright
claude mcp add    --scope user playwright -- npx @playwright/mcp@latest --browser chrome
# claude mcp remove --scope user chrome-devtools
# claude mcp add    --scope user chrome-devtools -- npx chrome-devtools-mcp@latest --autoConnect
