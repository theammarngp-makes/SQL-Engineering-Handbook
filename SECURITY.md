# Security Policy

## Overview

The **SQL Engineering Handbook** is an open-source educational repository. It contains SQL queries, schemas, markdown documentation, and analytical examples built on a self-designed three-table schema (`employees`, `departments`, `locations`). This file outlines how security concerns are handled in the context of this project.

> **Note:** This repository is an educational project and is not intended for production database deployments. Any SQL examples that modify data are clearly labeled and should only be executed in controlled learning environments.

---

## Scope

This repository is a **static documentation and learning resource**. It does not include:

- Live database connections
- Authentication systems
- API keys or credentials
- User data or personally identifiable information (PII)
- Backend services or deployable code

However, the following practices are enforced to maintain trust and integrity for all users, recruiters, and collaborators who reference this handbook.

---

## What to Report

Even for a documentation-first repository, the following are considered valid security concerns:

| Issue Type | Example |
|---|---|
| Hardcoded credentials | API keys, passwords, or tokens accidentally committed |
| Malicious scripts | Any `.sh`, `.py`, or embedded script with unintended behavior |
| Dependency vulnerabilities | If future tooling (e.g., MkDocs, Jupyter) is added |
| Misleading or harmful SQL | Queries designed to cause unintended destructive behavior |
| Sensitive data leakage | Accidentally committed personal data, even in sample CSVs |

---

## Reporting a Vulnerability

If you discover a security issue in this repository, please **do not open a public GitHub Issue**.

Instead, report it privately via:

- **Email:** theammarngp@gmail.com
- **GitHub:** [@theammarngp-makes](https://github.com/theammarngp-makes)
- **Subject line:** `[SECURITY] SQL Engineering Handbook — <brief description>`

### What to Include

- A clear description of the issue
- Steps to reproduce (if applicable)
- File path(s) affected
- Potential impact or risk

---

## Response Commitment

| Step | Timeline |
|---|---|
| Acknowledgement of report | Within **48 hours** |
| Initial assessment | Within **5 business days** |
| Resolution or workaround | Within **14 days** (depending on severity) |
| Public disclosure (if applicable) | After fix is confirmed |

---

## Security Best Practices in This Handbook

The SQL examples in this repository follow these principles:

- **No real data:** All datasets use fictional employee, department, and location records
- **No destructive queries by default:** `DROP`, `TRUNCATE`, and `DELETE` examples are clearly labeled and scoped
- **Schema transparency:** The full three-table schema is documented in `00_Resources/` so readers understand the exact data model behind every query
- **No credential exposure:** Connection strings, database URIs, and environment variables are never included
- **SQL injection awareness:** Parameterized queries are recommended whenever SQL is adapted for real-world applications

---

## Supported Versions

This is a living documentation project. Only the **latest version on the `main` branch** is actively maintained and considered current.

| Version / Branch | Supported |
|---|---|
| `main` (latest) | ✅ Yes |
| Older commits / forks | ❌ Not actively maintained |

---

## Acknowledgements

Security reports are taken seriously regardless of severity. Responsible disclosures will be credited in the repository's `README.md` under an Acknowledgements section (with reporter's permission).

Thank you for helping keep the SQL Engineering Handbook safe, trustworthy, and welcoming for learners and contributors worldwide.

---

*This document is maintained alongside the repository and may evolve as the project grows. — Mohammad Ammar ([@theammarngp-makes](https://github.com/theammarngp-makes))*
