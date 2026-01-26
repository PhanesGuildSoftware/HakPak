# HakPak3 Installation Parameters Guide

## Overview

HakPak3 now supports advanced installation filtering parameters that allow you to precisely control which tools get installed based on various criteria like compatibility score, size, RAM requirements, and tags.

## Features

### Filter by Compatibility Score
Install only tools that meet a minimum compatibility threshold with your system.

**Example:** Install only tools with 50% or better compatibility:
- Set minimum compatibility: `50`
- Set maximum compatibility: `100`

### Filter by Size
Limit installations to tools that fit within your disk space constraints.

**Example:** Install only tools under 500MB:
- Set maximum size: `500`

### Filter by RAM Requirements
Avoid tools that require too much RAM for your system.

**Example:** Install only tools requiring 2GB RAM or less:
- Set maximum RAM: `2048`

### Filter by Tags
Target specific tool categories or exclude unwanted types.

**Example:** Install only web security tools:
- Include tags: `web, http, webapp`

**Example:** Exclude database and forensics tools:
- Exclude tags: `database, forensics`

### Limit Installation Count
Control how many tools get installed in a batch.

**Example:** Install only the top 10 best-matching tools:
- Set max count: `10`

## Usage

### Method 1: Main Menu Option
1. Run HakPak3: `./hakpak3.sh` or `sudo python3 hakpak3.py`
2. Select option `3) Install Tools with Filters (Advanced)`
3. Configure your filter parameters interactively
4. Tools matching your filters will be displayed
5. Select tools to install

### Method 2: Within Install Menu
1. Run HakPak3 and select `2) Install Tools`
2. Type `filter` when prompted for tool names
3. Configure your filter parameters
4. The filtered tool list will be displayed

## Common Use Cases

### Case 1: High Compatibility Only
**Goal:** Install only tools that are highly compatible with your system (70%+)

**Settings:**
- Minimum compatibility: `70`
- Maximum compatibility: `100`
- All other filters: defaults

**Result:** Only tools with 70% or better compatibility scores will be shown and installable.

### Case 2: Small Tools Only
**Goal:** Install lightweight tools for systems with limited disk space

**Settings:**
- Maximum size: `100` (100MB)
- All other filters: defaults

**Result:** Only tools under 100MB total installation size.

### Case 3: Web Security Toolkit
**Goal:** Build a focused web application security toolkit

**Settings:**
- Include tags: `web, webapp, http`
- Minimum compatibility: `50`
- All other filters: defaults

**Result:** Only web-related security tools with decent compatibility.

### Case 4: Low-Resource System
**Goal:** Install tools suitable for a system with limited resources

**Settings:**
- Maximum size: `200` (200MB)
- Maximum RAM: `1024` (1GB)
- Minimum compatibility: `60`
- Max count: `15`

**Result:** Top 15 lightweight tools that work well on your system.

### Case 5: Network Tools, No Wireless
**Goal:** Install network tools but skip wireless-specific tools

**Settings:**
- Include tags: `network, scanning`
- Exclude tags: `wireless, wifi, bluetooth`
- Minimum compatibility: `50`

**Result:** Network security tools excluding wireless-specific utilities.

## Filter Parameters Reference

| Parameter | Type | Range | Default | Description |
|-----------|------|-------|---------|-------------|
| `min_compatibility` | Integer | 0-100 | 0 | Minimum compatibility score |
| `max_compatibility` | Integer | 0-100 | 100 | Maximum compatibility score |
| `max_size_mb` | Float | > 0 | None | Maximum total install size (MB) |
| `max_ram_mb` | Integer | > 0 | None | Maximum RAM requirement (MB) |
| `tags_filter` | List[str] | - | None | Include only these tags |
| `exclude_tags` | List[str] | - | None | Exclude these tags |
| `max_count` | Integer | > 0 | None | Maximum number to install |

## Compatibility Score Breakdown

The compatibility scoring system (0-100):

- **80-100**: Excellent match - Native packages available, good resource fit
- **60-79**: Good match - Can be installed with some adjustments
- **40-59**: Fair match - May require source compilation or workarounds
- **0-39**: Poor match - Limited or no support for your system

**Recommendation:** Set minimum compatibility to `50` for reliable installations.

## Examples in Practice

### Example 1: "Install all tools with 50% or better compatibility"
```
Main Menu → 3) Install Tools with Filters (Advanced)

Configuration:
  Minimum compatibility % [0]: 50
  Maximum compatibility % [100]: [Enter]
  Maximum size in MB [no limit]: [Enter]
  Maximum RAM in MB [no limit]: [Enter]
  Include tags [all]: [Enter]
  Exclude tags [none]: [Enter]
  Maximum tools [no limit]: [Enter]

Result: All tools with ≥50% compatibility shown
Action: Type 'all' to install ALL available tools, 'best20' for top 20, 'top5' for top 5, or select specific tools
```

### Example 2: "Install top 5 most compatible tools under 100MB"
```
Main Menu → 3) Install Tools with Filters (Advanced)

Configuration:
  Minimum compatibility % [0]: [Enter]
  Maximum compatibility % [100]: [Enter]
  Maximum size in MB [no limit]: 100
  Maximum RAM in MB [no limit]: [Enter]
  Include tags [all]: [Enter]
  Exclude tags [none]: [Enter]
  Maximum tools [no limit]: 5

Result: Top 5 tools under 100MB shown
Action: Type 'all' to install all 5
```

### Example 3: "Install web tools, min 60% compatibility"
```
Main Menu → 3) Install Tools with Filters (Advanced)

Configuration:
  Minimum compatibility % [0]: 60
  Maximum compatibility % [100]: [Enter]
  Maximum size in MB [no limit]: [Enter]
  Maximum RAM in MB [no limit]: [Enter]
  Include tags [all]: web,http,webapp
  Exclude tags [none]: [Enter]
  Maximum tools [no limit]: [Enter]

Result: Web-focused tools with ≥60% compatibility
Action: Select specific tools or type 'all'
```

## Tips and Best Practices

1. **Start Conservative**: Begin with higher compatibility thresholds (60-70%) for reliable installations
2. **Check Your Resources**: Use smaller size/RAM limits on constrained systems
3. **Use Tags Wisely**: Combine include/exclude tags for precise targeting
4. **Batch Wisely**: Use `max_count` to prevent overwhelming installations
5. **Iterate**: You can always run with different filters to install more tools later

## Technical Details

### How Filters Are Applied

1. **Load all available tools** from the Kali tools database
2. **Apply all filter criteria** in parallel (AND logic)
   - Compatibility score check
   - Size limit check
   - RAM requirement check
   - Tag inclusion check
   - Tag exclusion check
3. **Rank filtered tools** by compatibility score (best first)
4. **Apply count limit** if specified
5. **Display results** for user selection

### Filter Logic

All filters use **AND** logic - a tool must pass ALL specified criteria to be shown:

```python
tool_matches = (
    compatibility >= min_compat AND
    compatibility <= max_compat AND
    size <= max_size AND
    ram <= max_ram AND
    has_any_included_tag AND
    has_no_excluded_tags
)
```

## Troubleshooting

**No tools match filters:**
- Relax your criteria (lower min compatibility, increase max size/RAM)
- Remove or broaden tag filters
- Check that your filter values are reasonable

**Too many tools shown:**
- Increase minimum compatibility threshold
- Add more specific tag filters
- Use max_count to limit results

**Installation still fails:**
- Filters only control which tools are *offered*
- Actual installation depends on package availability
- Check system logs for specific package errors

---

**Developer:** Teyvone Wells  
**Company:** PhanesGuild Software LLC  
**Version:** 3.0.0
