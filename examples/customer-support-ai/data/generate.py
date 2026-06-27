#!/usr/bin/env python3
"""Generate deterministic customer-support smoke-test data and SQL inserts."""

from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "generated"

TABLES: dict[str, list[dict[str, Any]]] = {
    "customers": [
        {"customer_id": "C001", "customer_name": "Avery Chen", "segment": "enterprise", "region": "east", "lifecycle_status": "active", "signup_date": "2024-01-15"},
        {"customer_id": "C002", "customer_name": "Jordan Smith", "segment": "small_business", "region": "west", "lifecycle_status": "active", "signup_date": "2024-03-20"},
        {"customer_id": "C003", "customer_name": "Priya Patel", "segment": "midmarket", "region": "central", "lifecycle_status": "active", "signup_date": "2024-05-08"},
        {"customer_id": "C004", "customer_name": "Miguel Garcia", "segment": "small_business", "region": "south", "lifecycle_status": "at_risk", "signup_date": "2024-07-11"},
        {"customer_id": "C005", "customer_name": "Sam Taylor", "segment": "enterprise", "region": "west", "lifecycle_status": "active", "signup_date": "2024-08-23"},
        {"customer_id": "C006", "customer_name": "Nina Brown", "segment": "midmarket", "region": "east", "lifecycle_status": "active", "signup_date": "2024-11-02"},
        {"customer_id": "C007", "customer_name": "Leo Martin", "segment": "small_business", "region": "central", "lifecycle_status": "active", "signup_date": "2025-01-17"},
        {"customer_id": "C008", "customer_name": "Maya Wilson", "segment": "enterprise", "region": "south", "lifecycle_status": "at_risk", "signup_date": "2025-02-14"},
    ],
    "products": [
        {"product_id": "P001", "product_name": "Atlas Router", "category": "networking", "unit_price": 399.00, "launch_date": "2024-02-01"},
        {"product_id": "P002", "product_name": "Nimbus Sensor", "category": "iot", "unit_price": 149.00, "launch_date": "2024-04-01"},
        {"product_id": "P003", "product_name": "Helix Gateway", "category": "iot", "unit_price": 599.00, "launch_date": "2024-06-01"},
        {"product_id": "P004", "product_name": "Orbit Console", "category": "software", "unit_price": 99.00, "launch_date": "2024-08-01"},
        {"product_id": "P005", "product_name": "Pulse Battery", "category": "accessories", "unit_price": 49.00, "launch_date": "2024-10-01"},
        {"product_id": "P006", "product_name": "Vector Camera", "category": "security", "unit_price": 249.00, "launch_date": "2025-01-10"},
    ],
    "orders": [
        {"order_id": "O001", "customer_id": "C001", "order_ts": "2026-01-05 10:15:00", "channel": "direct", "order_status": "completed", "order_total": 798.00},
        {"order_id": "O002", "customer_id": "C002", "order_ts": "2026-01-08 09:30:00", "channel": "web", "order_status": "completed", "order_total": 149.00},
        {"order_id": "O003", "customer_id": "C003", "order_ts": "2026-01-10 14:45:00", "channel": "partner", "order_status": "completed", "order_total": 599.00},
        {"order_id": "O004", "customer_id": "C001", "order_ts": "2026-01-13 11:00:00", "channel": "web", "order_status": "completed", "order_total": 99.00},
        {"order_id": "O005", "customer_id": "C004", "order_ts": "2026-01-18 16:20:00", "channel": "web", "order_status": "returned", "order_total": 249.00},
        {"order_id": "O006", "customer_id": "C005", "order_ts": "2026-01-22 08:55:00", "channel": "direct", "order_status": "completed", "order_total": 1197.00},
        {"order_id": "O007", "customer_id": "C006", "order_ts": "2026-01-25 13:10:00", "channel": "web", "order_status": "completed", "order_total": 98.00},
        {"order_id": "O008", "customer_id": "C007", "order_ts": "2026-02-02 15:05:00", "channel": "partner", "order_status": "completed", "order_total": 448.00},
        {"order_id": "O009", "customer_id": "C008", "order_ts": "2026-02-07 10:40:00", "channel": "direct", "order_status": "completed", "order_total": 599.00},
        {"order_id": "O010", "customer_id": "C002", "order_ts": "2026-02-09 12:00:00", "channel": "web", "order_status": "refunded", "order_total": 99.00},
        {"order_id": "O011", "customer_id": "C003", "order_ts": "2026-02-15 17:25:00", "channel": "web", "order_status": "completed", "order_total": 298.00},
        {"order_id": "O012", "customer_id": "C006", "order_ts": "2026-02-20 09:15:00", "channel": "partner", "order_status": "completed", "order_total": 249.00},
    ],
    "order_items": [
        {"order_id": "O001", "line_id": 1, "product_id": "P001", "quantity": 2, "unit_price": 399.00, "returned_flag": False},
        {"order_id": "O002", "line_id": 1, "product_id": "P002", "quantity": 1, "unit_price": 149.00, "returned_flag": False},
        {"order_id": "O003", "line_id": 1, "product_id": "P003", "quantity": 1, "unit_price": 599.00, "returned_flag": False},
        {"order_id": "O004", "line_id": 1, "product_id": "P004", "quantity": 1, "unit_price": 99.00, "returned_flag": False},
        {"order_id": "O005", "line_id": 1, "product_id": "P006", "quantity": 1, "unit_price": 249.00, "returned_flag": True},
        {"order_id": "O006", "line_id": 1, "product_id": "P001", "quantity": 3, "unit_price": 399.00, "returned_flag": False},
        {"order_id": "O007", "line_id": 1, "product_id": "P005", "quantity": 2, "unit_price": 49.00, "returned_flag": False},
        {"order_id": "O008", "line_id": 1, "product_id": "P001", "quantity": 1, "unit_price": 399.00, "returned_flag": False},
        {"order_id": "O008", "line_id": 2, "product_id": "P005", "quantity": 1, "unit_price": 49.00, "returned_flag": False},
        {"order_id": "O009", "line_id": 1, "product_id": "P003", "quantity": 1, "unit_price": 599.00, "returned_flag": False},
        {"order_id": "O010", "line_id": 1, "product_id": "P004", "quantity": 1, "unit_price": 99.00, "returned_flag": True},
        {"order_id": "O011", "line_id": 1, "product_id": "P002", "quantity": 2, "unit_price": 149.00, "returned_flag": False},
        {"order_id": "O012", "line_id": 1, "product_id": "P006", "quantity": 1, "unit_price": 249.00, "returned_flag": False},
    ],
    "support_tickets": [
        {"ticket_id": "T001", "customer_id": "C001", "order_id": "O001", "product_id": "P001", "created_ts": "2026-03-01 09:00:00", "channel": "email", "priority": "high", "ticket_status": "open", "subject": "Duplicate invoice charge", "description": "The Atlas Router order was charged twice. Please reverse the duplicate charge before our month-end close.", "expected_category": "billing", "expected_sentiment": "negative"},
        {"ticket_id": "T002", "customer_id": "C003", "order_id": "O003", "product_id": "P003", "created_ts": "2026-03-02 10:30:00", "channel": "chat", "priority": "urgent", "ticket_status": "open", "subject": "Gateway offline after update", "description": "The Helix Gateway stopped connecting immediately after firmware 6.2. We need rollback instructions because production sensors are offline.", "expected_category": "technical", "expected_sentiment": "negative"},
        {"ticket_id": "T003", "customer_id": "C007", "order_id": "O008", "product_id": "P001", "created_ts": "2026-03-03 08:15:00", "channel": "web", "priority": "high", "ticket_status": "pending", "subject": "Shipment has not arrived", "description": "Tracking has not changed for six days and the Atlas Router shipment missed the promised delivery date.", "expected_category": "shipping", "expected_sentiment": "negative"},
        {"ticket_id": "T004", "customer_id": "C004", "order_id": "O005", "product_id": "P006", "created_ts": "2026-03-04 14:20:00", "channel": "email", "priority": "medium", "ticket_status": "closed", "subject": "Return label request", "description": "The Vector Camera housing arrived cracked. Please send the standard return label and replacement steps.", "expected_category": "returns", "expected_sentiment": "neutral"},
        {"ticket_id": "T005", "customer_id": "C002", "order_id": "O010", "product_id": "P004", "created_ts": "2026-03-05 16:40:00", "channel": "chat", "priority": "high", "ticket_status": "open", "subject": "Cannot sign in after password reset", "description": "The password reset link completes but Orbit Console still rejects the new password. The account is now locked.", "expected_category": "account", "expected_sentiment": "negative"},
        {"ticket_id": "T006", "customer_id": "C006", "order_id": "O007", "product_id": "P005", "created_ts": "2026-03-06 11:05:00", "channel": "web", "priority": "low", "ticket_status": "resolved", "subject": "Battery replacement worked", "description": "The Pulse Battery replacement fixed the issue. Thank you for the clear instructions and quick delivery.", "expected_category": "product", "expected_sentiment": "positive"},
        {"ticket_id": "T007", "customer_id": "C001", "order_id": "O004", "product_id": "P004", "created_ts": "2026-03-07 13:25:00", "channel": "email", "priority": "medium", "ticket_status": "closed", "subject": "Tax line explanation", "description": "Please explain why the latest Orbit Console invoice has a different tax line than our earlier order.", "expected_category": "billing", "expected_sentiment": "neutral"},
        {"ticket_id": "T008", "customer_id": "C008", "order_id": "O009", "product_id": "P003", "created_ts": "2026-03-08 07:50:00", "channel": "chat", "priority": "high", "ticket_status": "pending", "subject": "Intermittent gateway disconnects", "description": "The Helix Gateway connects after restart but drops again within an hour. Some sensors recover and others remain unavailable.", "expected_category": "technical", "expected_sentiment": "mixed"},
    ],
    "ticket_messages": [
        {"message_id": "M001", "ticket_id": "T001", "author_type": "customer", "message_ts": "2026-03-01 09:00:00", "message_body": "The card statement shows two identical charges for order O001."},
        {"message_id": "M002", "ticket_id": "T001", "author_type": "agent", "message_ts": "2026-03-01 09:20:00", "message_body": "I am comparing the payment records and will reverse the duplicate authorization."},
        {"message_id": "M003", "ticket_id": "T002", "author_type": "customer", "message_ts": "2026-03-02 10:30:00", "message_body": "All gateway-connected sensors went offline after firmware 6.2."},
        {"message_id": "M004", "ticket_id": "T002", "author_type": "agent", "message_ts": "2026-03-02 10:40:00", "message_body": "Keep the gateway powered and collect the diagnostic bundle before rollback."},
        {"message_id": "M005", "ticket_id": "T003", "author_type": "customer", "message_ts": "2026-03-03 08:15:00", "message_body": "The tracking page has shown label created for six days."},
        {"message_id": "M006", "ticket_id": "T003", "author_type": "agent", "message_ts": "2026-03-03 09:00:00", "message_body": "I opened a carrier trace and requested a replacement shipment if no scan appears today."},
        {"message_id": "M007", "ticket_id": "T004", "author_type": "customer", "message_ts": "2026-03-04 14:20:00", "message_body": "The camera housing is visibly cracked near the mount."},
        {"message_id": "M008", "ticket_id": "T004", "author_type": "agent", "message_ts": "2026-03-04 14:50:00", "message_body": "A prepaid return label and replacement order were issued."},
        {"message_id": "M009", "ticket_id": "T005", "author_type": "customer", "message_ts": "2026-03-05 16:40:00", "message_body": "I reset the password twice and now the account is locked."},
        {"message_id": "M010", "ticket_id": "T005", "author_type": "agent", "message_ts": "2026-03-05 16:55:00", "message_body": "I will verify identity, unlock the account, and invalidate the old reset links."},
        {"message_id": "M011", "ticket_id": "T006", "author_type": "customer", "message_ts": "2026-03-06 11:05:00", "message_body": "The replacement battery solved the problem."},
        {"message_id": "M012", "ticket_id": "T006", "author_type": "agent", "message_ts": "2026-03-06 11:20:00", "message_body": "Thank you for confirming. I am closing the case as resolved."},
        {"message_id": "M013", "ticket_id": "T007", "author_type": "customer", "message_ts": "2026-03-07 13:25:00", "message_body": "Why did the tax amount change on this invoice?"},
        {"message_id": "M014", "ticket_id": "T007", "author_type": "agent", "message_ts": "2026-03-07 14:05:00", "message_body": "The tax changed because the billing location was updated before renewal."},
        {"message_id": "M015", "ticket_id": "T008", "author_type": "customer", "message_ts": "2026-03-08 07:50:00", "message_body": "Restarting helps briefly, but the gateway disconnects again."},
        {"message_id": "M016", "ticket_id": "T008", "author_type": "agent", "message_ts": "2026-03-08 08:10:00", "message_body": "I am checking firmware compatibility and signal logs before scheduling replacement."},
    ],
    "knowledge_articles": [
        {"article_id": "A001", "product_id": None, "title": "Resolve duplicate payment charges", "article_body": "Confirm that the charges share the same order and amount. Distinguish a duplicate authorization from a settled duplicate charge. Reverse the duplicate transaction, explain the refund timing, and attach the payment audit record.", "policy_tags": "billing,payments,refund"},
        {"article_id": "A002", "product_id": "P003", "title": "Helix Gateway firmware rollback", "article_body": "Collect diagnostics before changing firmware. Keep the gateway powered, download the signed previous firmware, verify its checksum, perform the rollback, and confirm sensor connectivity. Escalate if the gateway remains offline.", "policy_tags": "technical,firmware,gateway"},
        {"article_id": "A003", "product_id": None, "title": "Investigate stalled shipment tracking", "article_body": "Open a carrier trace when tracking has no scan for more than three business days. Confirm the delivery address and create a replacement shipment when the carrier cannot locate the package.", "policy_tags": "shipping,tracking,replacement"},
        {"article_id": "A004", "product_id": "P006", "title": "Create a return label for damaged hardware", "article_body": "Record photographs of the damage, confirm the serial number, create a prepaid return label, and place the replacement order. Do not require the customer to pay return shipping for arrival damage.", "policy_tags": "returns,damage,label"},
        {"article_id": "A005", "product_id": "P004", "title": "Recover a locked Orbit Console account", "article_body": "Verify the customer's identity, unlock the account, invalidate old password-reset links, issue one new reset link, and confirm successful sign-in. Escalate repeated lockouts to the identity team.", "policy_tags": "account,password,identity"},
        {"article_id": "A006", "product_id": "P005", "title": "Replace a Pulse Battery", "article_body": "Power down the device, remove the old battery, inspect the connector, install the replacement battery, and run the health check. Close the ticket only after the customer confirms normal operation.", "policy_tags": "product,battery,replacement"},
    ],
}


def sql_literal(value: Any, dialect: str) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        if dialect == "fabric":
            return "1" if value else "0"
        return "TRUE" if value else "FALSE"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def write_csvs(output: Path) -> None:
    csv_dir = output / "csv"
    csv_dir.mkdir(parents=True, exist_ok=True)
    for table, rows in TABLES.items():
        with (csv_dir / f"{table}.csv").open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)


def render_insert(
    table: str,
    rows: list[dict[str, Any]],
    target: str,
    suffix: str,
    dialect: str,
) -> str:
    columns = ", ".join(rows[0])
    values = ",\n  ".join(
        "("
        + ", ".join(sql_literal(row[column], dialect) for column in rows[0])
        + ")"
        for row in rows
    )
    return f"INSERT INTO {target}.{table} ({columns}) VALUES\n  {values};{suffix}"


def write_sql(output: Path) -> None:
    sql_dir = output / "sql"
    sql_dir.mkdir(parents=True, exist_ok=True)
    common = "\n\n".join(
        "-- open-skills-statement\n"
        + render_insert(table, rows, "__TARGET__", "", "common")
        for table, rows in TABLES.items()
    )
    (sql_dir / "databricks_inserts.sql").write_text(common + "\n", encoding="utf-8")
    (sql_dir / "snowflake_inserts.sql").write_text(common + "\n", encoding="utf-8")

    fabric = "\n\n".join(
        render_insert(table, rows, "dbo", "\nGO", "fabric")
        for table, rows in TABLES.items()
    )
    (sql_dir / "fabric_inserts.sql").write_text(fabric + "\n", encoding="utf-8")


def write_knowledge_base(output: Path) -> None:
    lines = ["# Customer Support Knowledge Base", ""]
    for article in TABLES["knowledge_articles"]:
        lines.extend(
            [
                f"## {article['article_id']}: {article['title']}",
                "",
                f"Product: {article['product_id'] or 'all'}",
                f"Tags: {article['policy_tags']}",
                "",
                str(article["article_body"]),
                "",
            ]
        )
    (output / "knowledge_base.md").write_text("\n".join(lines), encoding="utf-8")


def write_manifest(output: Path) -> None:
    source_text = " ".join(
        str(row.get("description", "")) + " " + str(row.get("article_body", ""))
        for rows in TABLES.values()
        for row in rows
    )
    manifest = {
        "dataset": "customer-support-ai",
        "version": 1,
        "row_counts": {table: len(rows) for table, rows in TABLES.items()},
        "estimated_source_tokens": math.ceil(len(source_text) / 4),
        "ai_ticket_rows": len(TABLES["support_tickets"]),
        "eval_prompts": 10,
    }
    (output / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    write_csvs(output)
    write_sql(output)
    write_knowledge_base(output)
    write_manifest(output)
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
