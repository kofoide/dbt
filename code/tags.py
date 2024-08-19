import contextlib
import json
import os
from dbt.cli.main import dbtRunner, dbtRunnerResult


# initialize
dbt = dbtRunner()

# create CLI args as a list of strings
cli_args = ["ls", "--quiet", "--output", "json", "--output-keys", "tags"]

with open(os.devnull, encoding="utf-8") as f, contextlib.redirect_stdout(f):
    res: dbtRunnerResult = dbt.invoke(cli_args)

unique_tags = set()

# parse output
for r in res.result:
    j = json.loads(r)

    for tag in j["tags"]:
        unique_tags.add(tag)

# write to file
print(json.dumps(list(unique_tags), indent=4))
