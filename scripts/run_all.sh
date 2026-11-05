#!/usr/bin/env bash
# =====================================================================
# File:    run_all.sh
# Purpose: Run all HMS SQL files in numeric order via sqlplus.
# Usage:   ./run_all.sh username/password@//host:port/service
# Example: ./run_all.sh hms_user/secret@//localhost:1521/XEPDB1
# Author:  HMS Project
# Date:    2025
# =====================================================================

set -euo pipefail

# ---- Validate args ---------------------------------------------------
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <username/password@//host:port/service>"
  echo "Example: $0 hms_user/secret@//localhost:1521/XEPDB1"
  exit 2
fi

CONNECTION="$1"

# ---- Resolve the sql/ directory relative to this script --------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$(cd "${SCRIPT_DIR}/../sql" && pwd)"

if [ ! -d "${SQL_DIR}" ]; then
  echo "ERROR: sql directory not found at ${SQL_DIR}" >&2
  exit 2
fi

# ---- Verify sqlplus is available -------------------------------------
if ! command -v sqlplus >/dev/null 2>&1; then
  echo "ERROR: sqlplus not found on PATH. Install Oracle Instant Client." >&2
  exit 2
fi

echo "================================================================"
echo "  Hospital Management System - full schema load"
echo "  Connection: ${CONNECTION}"
echo "  SQL dir:    ${SQL_DIR}"
echo "================================================================"

# ---- Run every .sql file in numeric order ----------------------------
# WHENEVER SQLERROR EXIT SQL.SQLCODE  -> abort on the first error
# SET DEFINE OFF                       -> don't interpret & as substitution
# The files are sorted by their numeric prefix (01_, 02_, ...).
cd "${SQL_DIR}"

GLOBAL_RC=0
for f in $(ls *.sql | sort); do
  echo
  echo "----------------------------------------------------------------"
  echo "  Running ${f}"
  echo "----------------------------------------------------------------"
  if sqlplus -S -L "${CONNECTION}" <<SQL
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET DEFINE OFF;
SET SERVEROUTPUT ON;
PROMPT >>> ${f}
@${f}
COMMIT;
SQL
  then
    echo "  [OK] ${f}"
  else
    RC=$?
    echo "  [FAIL] ${f} (sqlplus exit code ${RC})" >&2
    GLOBAL_RC=${RC}
    break
  fi
done

echo
echo "================================================================"
if [ "${GLOBAL_RC}" -eq 0 ]; then
  echo "  All SQL files executed successfully."
else
  echo "  Run aborted with exit code ${GLOBAL_RC}."
fi
echo "================================================================"
exit "${GLOBAL_RC}"
