# TSV

The query contained in `mappings/greek-lowfat-to-tsv.xq` is used to generate `macula-greek-Nestle1904.tsv`.

It can be ran against BaseX via the following command:

```shell
# assumes macula-greek repository root context
basex -i Nestle1904/lowfat/nestle1904lowfat.xml \
    -o Nestle1904/tsv/macula-greek-Nestle1904.tsv \
    mappings/greek-lowfat-to-tsv.xq
```

The [csv-diff](https://pypi.org/project/csv-diff/) Python library may be useful for diffing TSVs:

```shell
# rename the existing file
mv Nestle1904/tsv/macula-greek-Nestle1904.tsv Nestle1904/tsv/macula-greek-Nestle1904-original.tsv

# run the mappings/greek-lowfat-to-tsv.xq script as instructed above

# install csv-diff
pip3 install csv-diff

# run a diff and summarize output in JSON
csv-diff --key="xml:id" --json Nestle1904/tsv/macula-greek-Nestle1904-original.tsv \
    Nestle1904/tsv/macula-greek-Nestle1904.tsv

# optionally use JQ (https://stedolan.github.io/jq/) to get a list of changed IDs
csv-diff --key="xml:id" --json Nestle1904/tsv/macula-greek-Nestle1904-original.tsv \
    Nestle1904/tsv/macula-greek-Nestle1904.tsv \
    | jq '.changed | .[] .key' -r

# remove macula-greek-Nestle1904-original.tsv
rm Nestle1904/tsv/macula-greek-Nestle1904-original.tsv
```