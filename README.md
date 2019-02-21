# cxresttest
Script showing the LOC, scan date, and scan origin (e.g. Jenkins, CLI, Web ui etc) for the latest scan for all projects scanned within the last three months.
It uses curl for making REST API calls and jq to manipulate the JSON output, then generates the output in CSV.
