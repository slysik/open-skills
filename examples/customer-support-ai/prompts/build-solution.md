# Build Request

Build a customer-support resolution copilot on the current platform.

Load the provided seven-table customer-support dataset. Create a customer 360
view and a ticket operations view. Enrich every support ticket with a concise
summary, one of the categories billing/technical/shipping/returns/account/product,
and sentiment. Add grounded retrieval over the knowledge articles. Support
natural-language questions about customers, orders, products, and tickets.

Use platform-native governance, SQL, AI functions, search, and evaluation
features. Use CLIs first and REST APIs only when the CLI does not expose the
required operation. Do not use MCP tools.

Record commands, elapsed time, token usage, platform compute or AI cost, errors,
and any feature that could not be completed.
