# Terraform Functions — Complete Guide

This guide groups Terraform functions by category and provides concise explanations and HCL examples you can copy into your configurations. It includes the example expressions you provided (upper, lower, trim, replace, substr, max/min, length, concat, merge, toset, tonumber, tostring, timestamp, formatdate) and many commonly used functions across categories.

Reference: <https://developer.hashicorp.com/terraform/language/functions>

---

## Table of contents

- String Functions
- Numeric Functions
- Collection Functions
- Type Conversion
- Date / Time
- Filesystem & Template
- Encoding
- Hash / Crypto
- IP Network
- Tips & Common Gotchas

---

## String Functions

Transform and manipulate strings.

- `upper(string)` — returns the string in uppercase.

Example:

```hcl
locals { example = upper("hello aws") }
// result: "HELLO AWS"
```

- `lower(string)` — returns the string in lowercase.

```hcl
locals { example = lower("HELLO") }
// result: "hello"
```

- `trim(str, cutset)` — remove all leading and trailing characters in `cutset` from `str`.

Note: `trim()` requires a `cutset` argument. Calling `trim("abc")` will error.

Examples:

```hcl
trim("biscnb  wdnc ", " ")   // "biscnb  wdnc"
trim("biscnb  wdnc ", "c")   // "biscnb  wdnc " (removes `c` from ends)
trim("biscnb  wdnc ", "c ")  // "biscnb  wdn" (removes c and space)
```

- `replace(string, search, replace)` — replace substrings.

```hcl
replace("aws", "w", "W") // "aWs"
```

- `substr(string, offset, length)` — return substring.

```hcl
substr("hello", 0, 3) // "hel"
```

- `split(sep, string)` — splits into a list of strings.
- `join(sep, list)` — join list to a string.

Example combining functions:

```hcl
locals {
  raw = " a,b,c "
  parts = split(",", trim(raw, " "))
}
```

---

## Numeric Functions

- `max(numbers...)` — returns the maximum.
- `min(numbers...)` — returns the minimum.

Examples:

```hcl
max(12,1,3) // 12
min(12,2,3,3) // 2
```

- `abs(n)` — absolute value
- `ceil(n)`, `floor(n)`, `round(n)` — rounding helpers

---

## Collection Functions

Operations for lists, sets, and maps.

- `length(collection)` — number of elements (strings, lists, maps).

```hcl
length([1,2,3,4,5,6,7,8,42,23,43,5,6]) // 13
```

- `concat(list1, list2, ...)` — concatenate lists.

```hcl
concat([12,2,2], [23,3,23])
// [12, 2, 2, 23, 3, 23]
```

- `merge(map1, map2, ...)` — merge maps (later keys override earlier ones).

```hcl
merge({"sa"="ds"}, {"dsa"="da"})
// { dsa = "da", sa = "ds" }
```

- `toset(list)` — convert a list to a set (unique elements).

```hcl
toset([1,2,3,4,2,2,3,2,42,4,2,4,3])
// toset([1,2,3,4,42])
```

- `flatten(list_of_lists)`, `compact(list)` — flatten nested lists and remove nulls
- `contains(collection, value)` — whether list contains value
- `index(list, value)` — position of value
- `slice(list, start, end)` — sub-slice of a list
- `keys(map)` / `values(map)` — list of map keys or values

Example building security group rules from ports (typical usage):

```hcl
locals {
  ports_list = split(",", "22,80,443")
  sg_rules = [for p in local.ports_list : {
    from_port = tonumber(p)
    to_port   = tonumber(p)
    protocol  = "tcp"
  }]
}
```

---

## Type Conversion

- `tonumber(string)` — converts a numeric string to number.
- `tostring(value)` — converts a value to string.

Examples:

```hcl
tonumber("12") // 12
tostring(12)     // "12"
```

Note: conversion failures cause plan-time errors.

---

## Date / Time

- `timestamp()` — current time in UTC ISO 8601 format.
- `formatdate(layout, timestamp)` — format timestamps using `DD`, `MM`, `YYYY`, `HH`, `mm`, `ss` tokens.

Examples:

```hcl
timestamp() // "2026-06-04T15:01:46Z"
formatdate("DD-MM-YYYY", timestamp()) // "04-06-2026"
```

Notes:

- `timestamp()` is evaluated at plan/apply time when used as an expression; avoid it in resources you expect to be identical between runs unless intended.

---

## Filesystem & Template

- `file(path)` — return file contents as string.
- `fileset(path, pattern)` — list files matching pattern.
- `templatefile(path, vars)` — render a template with variables.

Example:

```hcl
locals { user_data = file("./cloud-init.sh") }
```

---

## Encoding

- `base64encode(string)` / `base64decode(string)` — base64 encode/decode.

Example:

```hcl
base64encode("hello") // "aGVsbG8="
```

---

## Hash / Crypto

- `md5(string)`, `sha1(string)`, `sha256(string)`, `sha512(string)` — cryptographic hash strings.

Example:

```hcl
sha256("my-secret")
```

---

## IP Network

- `cidrsubnet(prefix, newbits, netnum)` — create a subnet from CIDR
- `cidrhost(prefix, hostnum)` — get host IP in CIDR
- `cidrnetmask(prefix)` — netmask string

Example:

```hcl
cidrsubnet("10.0.0.0/16", 8, 1) // "10.1.0.0/24" (example)
```

---

## Tips & Common Gotchas

- Many functions are strict about argument types. Convert with `tonumber()`/`tostring()` when necessary.
- `trim()` requires a `cutset` (characters to remove). If you intended to remove spaces use `trim("my string", " ")`.
- `merge()` expects maps; malformed HCL (broken quotes or missing braces) will cause parser errors.
- `timestamp()` changes between plans; use with care in equality-sensitive resources.
- Use `for` expressions and `dynamic` blocks to convert collections into nested block structures.

---

## Examples you provided (console snippets)

```hcl
# strings
upper("hello aws")        // "HELLO AWS"
lower("HELLO")           // "hello"
trim("biscnb  wdnc ", " ") // "biscnb  wdnc"
replace("aws","w","W") // "aWs"
substr("hello",0,3)      // "hel"

# numbers
max(12,1,3)                // 12
min(12,2,3,3)              // 2

# collections
length([1,2,3,4,5,6,7,8,42,23,43,5,6]) // 13
concat([12,2,2],[23,3,23]) // [12,2,2,23,3,23]
merge({"sa"="ds"},{"dsa"="da"}) // merged map
toset([1,2,3,4,2,2,3,2,42,4,2,4,3]) // set of unique elements

# conversions
tonumber("12") // 12
tostring(12)     // "12"

# time
timestamp()                            // e.g. "2026-06-04T15:01:46Z"
formatdate("DD-MM-YYYY", timestamp()) // "04-06-2026"
```

---

If you want, I can:

- Add runnable HCL module examples that demonstrate each category (e.g., a small module that uses many functions).
- Add a printable cheatsheet with one-line examples.
- Link specific functions in the official docs for quick lookup.

File: [day11/terraform-functions.md](day11/terraform-functions.md)

---

## Locals.tf — Detailed explanation and safer example

This section documents the `locals` block in [day11/locals.tf](day11/locals.tf#L1-L41). It explains each local value, common pitfalls, and provides a safer, robust `locals` example you can paste into your configuration.

### Field-by-field explanation

- `formatted_project_name`
  - Expression: `lower(replace(var.project_name, " ", "-"))`
  - Purpose: produce a normalized, lowercase name with spaces replaced by hyphens (useful for tags or resource names).
  - Notes: consecutive spaces become consecutive hyphens; use `regexreplace()` if you want to collapse sequences or remove non-alphanumeric characters.

- `new_tag`
  - Expression: `merge(var.default_tag, var.envionment_tags)`
  - Purpose: combine a default tags map with environment-specific tags; environment keys override defaults.

- `formatted_bucket_name`
  - Expression: `replace(replace(lower(substr(var.bucket_name,0,63)), " ", "-"), "()", "-")`
  - Purpose: attempt to meet S3 naming constraints (lowercase, hyphens, <=63 chars).
  - Pitfalls: the `replace("()","-")` only matches the literal `()` string; it won't catch single parentheses or other invalid characters. It's better to normalize non-allowed chars using `regexreplace()` and then `substr()`.

- `ports_list`
  - Expression: `split(",", var.multiple_ports)`
  - Purpose: convert a CSV string to a list of strings (e.g., `"80,443"` → `["80","443"]`).
  - Notes: `split()` doesn't trim whitespace. Trim entries in a for-expression if inputs may include spaces.

- `sg_rules`
  - Uses a for-expression to produce a list of objects describing security-group rules.
  - Recommendation: convert port strings to numbers with `tonumber()` if downstream resources expect numeric ports.

- `instance_size`
  - Expression: `lookup(var.instance_size, var.environment, "t3.micro")`
  - Purpose: pick instance size per environment with a default fallback.

- `all_locations` / `unique_locations`
  - `concat()` joins lists; `toset()` deduplicates. Note sets are unordered; if order matters, convert back to a list after deduplication with `tolist(toset(...))` and be aware order is not guaranteed.

- `positive_cost`, `max_cost`, `min_cost`, `total_cost`, `average_cost`
  - `positive_cost = [for cost in var.monthly_costs : abs(cost)]` makes values positive.
  - Use variadic expansion (`...`) to call `max()`/`min()` on a list: `max(local.positive_cost...)`.
  - Guard against empty lists before using `max()`/`min()` or dividing for averages.

- `timestamp()` and `formatdate()`
  - `timestamp()` returns an ISO-8601 string representing the current time. Use `formatdate()` to format it. Use the same `local.current_time` value for multiple formats to keep them consistent between expressions.

- `fileexists()` / `file()` / `jsondecode()`
  - `fileexists(path)` returns a boolean.
  - `file(path)` reads a file's contents as a string; `jsondecode()` parses JSON into maps/lists.
  - These functions operate on the local filesystem where Terraform runs; ensure files are present in CI or remote runs. Use `try()` to handle parse errors gracefully.

### Common pitfalls & fixes

- Empty collections: guard `max/min` and average calculations with `length(...) > 0` checks to avoid runtime errors.
- `trim()` requires a `cutset` parameter — e.g., `trim(str, " ")` to trim spaces.
- `replace()` only matches exact substrings; for broader cleaning use `regexreplace()`.
- `toset()` removes duplicates but also removes ordering; only use `toset()` when order is not important.

### Safer, robust `locals` example

This version improves sanitization, trims CSV entries, converts port strings to numbers, and guards against empty lists:

```hcl
locals {
  formatted_project_name = lower(regexreplace(trim(var.project_name), "\s+", "-"))

  new_tag = merge(var.default_tag, var.envionment_tags)

  sanitized_name = regexreplace(lower(var.bucket_name), "[^a-z0-9-]+", "-")
  formatted_bucket_name = substr(regexreplace(sanitized_name, "-+", "-"), 0, 63)

  ports_list = [for p in split(",", var.multiple_ports) : trim(p, " ")]

  sg_rules = [for p in local.ports_list : {
    name        = "Allow port ${p}"
    port        = tonumber(p)
    description = "Allow traffic on port ${p}"
  }]

  instance_size = lookup(var.instance_size, var.environment, "t3.micro")

  all_locations    = concat(var.user_locations, var.default_location)
  unique_locations = tolist(toset(local.all_locations))

  positive_cost = [for c in var.monthly_costs : abs(c)]
  max_cost = length(local.positive_cost) > 0 ? max(local.positive_cost...) : 0
  min_cost = length(local.positive_cost) > 0 ? min(local.positive_cost...) : 0
  total_cost = sum(local.positive_cost)
  average_cost = length(local.positive_cost) > 0 ? local.total_cost / length(local.positive_cost) : 0

  current_time = timestamp()
  format1 = formatdate("YYYY-MM-DD HH:mm:ss", local.current_time)
  format2 = formatdate("DD/MM/YYYY", local.current_time)

  config_file_exists = fileexists("./config.json")
  config_data = try(jsondecode(file("./config.json")), {
    bucket_name = "default-bucket-name"
    default_tag = { Owner = "Default Owner" Project = "Default Project" }
    envionment_tags = { Environment = "Default Environment" }
  })
}
```

### Suggested edits you can make to `day11/locals.tf`

- Replace repeated hyphen logic in `formatted_bucket_name` with the `sanitized_name` approach above.
- Convert `port` values to numbers in `sg_rules` using `tonumber()`.
- Add guards for `max/min` and average to avoid errors on empty lists.
- Use `try()` around `jsondecode(file(...))` to handle missing/invalid JSON gracefully.

If you want, I can apply these changes directly to `day11/locals.tf` and run a `terraform validate` command template for you to run locally. Tell me if you want me to patch the file now.

---

## Day 11: `locals` examples — functions used and explanations

Below are the common functions and patterns used in the `locals` block you provided, with corrected and runnable HCL snippets and brief notes about behavior and gotchas.

Example `locals` (simplified and corrected for clarity):

```hcl
locals {
  # normalize project name: replace spaces with hyphens and lowercase
  formatted_project_name = lower(replace(var.project_name, " ", "-"))

  # merge two maps (later keys override earlier ones)
  new_tag = merge(var.default_tag, var.envionment_tags)

  # format bucket name: lowercase, take first 63 chars, replace spaces and parentheses
  formatted_bucket_name = replace(replace(lower(substr(var.bucket_name, 0, 63)), " ", "-"), "()", "-")

  # split CSV string into list
  ports_list = split(",", var.multiple_ports)

  # generate a list of SG rules using a for-expression
  sg_rules = [for port in local.ports_list : {
    name        = "Allow port ${port}"
    port        = tonumber(port)
    description = "Allow traffic on port ${port}"
  }]

  # lookup in a map with a default fallback
  instance_size = lookup(var.instance_size, var.environment, "t3.micro")

  # combine lists and deduplicate using toset()
  all_locations    = concat(var.user_locations, var.default_location)
  unique_locations = toset(local.all_locations)

  # make all costs positive and compute stats
  positive_cost = [for cost in var.monthly_costs : abs(cost)]
  max_cost      = max(local.positive_cost...)
  min_cost      = min(local.positive_cost...)
  total_cost    = sum(local.positive_cost)
  average_cost  = local.total_cost / length(local.positive_cost)

  # timestamps and formatting
  current_time = timestamp()
  format1      = formatdate("YYYY-MM-DD HH:mm:ss", local.current_time)
  format2      = formatdate("DD/MM/YYYY", local.current_time)

  # conditional file read: test file exists, then parse JSON, otherwise use defaults
  config_file_exists = fileexists("./config.json")
  config_data = config_file_exists ? jsondecode(file("./config.json")) : {
    bucket_name = "default-bucket-name"
    default_tag = {
      Owner   = "Default Owner"
      Project = "Default Project"
    }
    envionment_tags = {
      Environment = "Default Environment"
    }
  }
}
```

Function notes and clarifications:

- `lower()` + `replace()` — common normalization pattern to make resource names DNS-friendly.
- `substr(string, 0, 63)` — truncate to 63 characters to meet many provider limits (S3, etc.).
- `split(",", var.multiple_ports)` returns a list of strings; use `tonumber()` when numeric values are required.
- For-expressions produce transformed collections; here we convert string ports into rule objects.
- `lookup(map, key, default)` safely retrieves map values with a fallback.
- `concat(list1, list2)` joins lists; `toset()` converts to a set (removes duplicates). If you need a deduplicated list again, use `tolist(toset(...))` but note sets are unordered.
- `abs(number)` returns absolute value.
- Variadic expansion `...` — many functions like `max()` and `min()` accept a variable number of numeric arguments. To call them with a list, expand the list with `...` as shown: `max(local.positive_cost...)`.
- `sum(list)` and `length(list)` are handy for aggregates and averages.
- `timestamp()` returns an ISO 8601 string; use `formatdate()` to render human-friendly layouts.
- `fileexists(path)` returns `true`/`false` if the file exists. `file(path)` reads file contents as a string. `jsondecode(string)` parses JSON into Terraform maps/lists and can then be merged or used directly.

Common pitfalls shown here:

- Passing a list where a variadic argument list is expected — fix with `...` expansion.
- `toset()` removes duplicates but also loses ordering; use only when order doesn't matter.
- `substr()` can panic if the requested length goes past string end — in Terraform `substr()` will clamp; still validate inputs for safety.
- `file()` and `fileexists()` operate on files available to the machine running Terraform; in remote runs (e.g., in a CI container) ensure the file is present.

Use this section as a ready reference for the `locals` you have in `day11/variables.tf`.
