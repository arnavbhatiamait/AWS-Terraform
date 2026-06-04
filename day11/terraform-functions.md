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
